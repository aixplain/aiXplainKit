# RFC-0001: Auth and Credentials

| Field        | Value                                    |
|--------------|------------------------------------------|
| Status       | Implemented                              |
| Authors      |                                          |
| Created      | 2026-03-06                               |
| Depends on   | --                                       |
| Depended by  | RFC-0002, RFC-0003                       |
| Priority     | P0 -- Foundation                         |

## Context

The current Swift SDK manages authentication through a singleton `APIKeyManager` that loads keys from `ProcessInfo` environment variables and exposes mutable properties (`TEAM_API_KEY`, `AIXPLAIN_API_KEY`, `PIPELINE_API_KEY`, `MODEL_API_KEY`, `HF_TOKEN`). Header construction lives in `Networking+Metadata.buildHeader()`, which silently prefers `TEAM_API_KEY` over `AIXPLAIN_API_KEY` when both are set.

### How Python v2 handles auth

The Python SDK v2 enforces **mutual exclusivity** at the client level (`client.py`):

```python
# From client.py -- AixplainClient.__init__
if not (self.aixplain_api_key or self.team_api_key):
    raise ValueError("Either `aixplain_api_key` or `team_api_key` should be set")

if self.aixplain_api_key and self.team_api_key:
    raise ValueError("Either `aixplain_api_key` or `team_api_key` should be set")

headers = {"Content-Type": "application/json"}
if self.aixplain_api_key:
    headers["x-aixplain-key"] = self.aixplain_api_key
if self.team_api_key:
    headers["x-api-key"] = self.team_api_key
```

The top-level `Aixplain` entry point (`core.py`) resolves the key once:

```python
# From core.py -- Aixplain.__init__
self.api_key = api_key or os.getenv("TEAM_API_KEY") or ""
assert self.api_key, (
    "API key is required. You should either pass it as an argument or "
    "set the TEAM_API_KEY environment variable."
)
```

Key observations from Python v2:
1. Exactly one key type is accepted -- never both.
2. `TEAM_API_KEY` is the default environment variable (not `AIXPLAIN_API_KEY`).
3. The header name differs by key type: `x-aixplain-key` vs `x-api-key`.
4. Validation happens at init time with a clear error message.
5. The key is set once on the session headers and reused for all requests.

### Problems in the current Swift SDK

1. **Global mutable singleton** -- any part of the code can mutate `APIKeyManager.shared` at any time, making behavior unpredictable in concurrent contexts and impossible to scope per-client.
2. **Silent override** -- `buildHeader()` overwrites headers when both key types exist; there is no error or warning. Python v2 explicitly rejects this.
3. **No validation** -- keys are used as-is with no format or emptiness check. Python v2 asserts non-empty at init.
4. **Mixed concerns** -- `APIKeyManager` also holds `BACKEND_URL` and `MODELS_RUN_URL`, coupling auth with endpoint configuration. Python v2 separates these: URLs go on `Aixplain`, keys go on `AixplainClient`.
5. **No key-type enum** -- the distinction between aiXplain key and team key is implicit in property names, not in a typed contract.
6. **Team key uses wrong header** -- Swift sends `Authorization: Token <key>`, Python v2 sends `x-api-key: <key>`. The Swift SDK must align to the v2 header contract.
7. **Unused keys** -- `PIPELINE_API_KEY` and `MODEL_API_KEY` are never referenced outside `APIKeyManager`; they are dead code.

## Decision

Introduce a `Credential` value type that enforces mutual exclusivity and maps to the correct header name, matching the Python v2 contract exactly.

## API Shape

```swift
/// How the SDK authenticates against the aiXplain platform.
/// Matches Python v2: exactly one key type per client instance.
public enum AuthenticationScheme: Sendable, Codable {
    /// Platform-scoped key sent as `x-aixplain-key`.
    /// Python v2: `headers["x-aixplain-key"] = self.aixplain_api_key`
    case aixplainKey(String)

    /// Team-scoped key sent as `x-api-key`.
    /// Python v2: `headers["x-api-key"] = self.team_api_key`
    case teamKey(String)
}

/// Resolved, validated credential ready for use in requests.
/// Immutable once created -- matches Python v2 pattern where
/// headers are set once on the session during __init__.
public struct Credential: Sendable, Equatable, Codable {
    public let scheme: AuthenticationScheme

    /// Validates and creates a credential.
    /// Throws `AuthError.emptyKey` if the key string is empty.
    /// Mirrors Python v2: `assert self.api_key` in core.py.
    public init(scheme: AuthenticationScheme) throws {
        switch scheme {
        case .aixplainKey(let key), .teamKey(let key):
            guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw AuthError.emptyKey
            }
        }
        self.scheme = scheme
    }

    /// Builds the authentication header pair for this credential.
    /// Returns (headerField, headerValue) matching the Python v2 contract.
    public func authHeaders() -> [String: String] {
        var headers = ["Content-Type": "application/json"]
        switch scheme {
        case .aixplainKey(let key):
            headers["x-aixplain-key"] = key
        case .teamKey(let key):
            headers["x-api-key"] = key
        }
        return headers
    }

    /// Resolves a credential from explicit value or environment.
    /// Resolution order matches Python v2 core.py:
    ///   1. Explicit `apiKey` parameter
    ///   2. `TEAM_API_KEY` environment variable
    ///   3. Throw error
    public static func resolve(
        apiKey: String? = nil,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> Credential {
        if let key = apiKey, !key.isEmpty {
            return try Credential(scheme: .teamKey(key))
        }
        if let envKey = environment["TEAM_API_KEY"], !envKey.isEmpty {
            return try Credential(scheme: .teamKey(envKey))
        }
        if let envKey = environment["AIXPLAIN_API_KEY"], !envKey.isEmpty {
            return try Credential(scheme: .aixplainKey(envKey))
        }
        throw AuthError.noCredentialFound
    }
}

/// Authentication errors.
public enum AuthError: Error, Sendable, LocalizedError {
    case noCredentialFound
    case emptyKey
    case bothKeysProvided

    public var errorDescription: String? {
        switch self {
        case .noCredentialFound:
            return "API key is required. Pass it as an argument or set the TEAM_API_KEY environment variable."
        case .emptyKey:
            return "API key must not be empty."
        case .bothKeysProvided:
            return "Either `aixplainKey` or `teamKey` should be set, not both."
        }
    }
}
```

### Header mapping (Python v2 parity)

| Key Type    | Python v2 Header    | Current Swift Header         | v2 Swift Header     |
|-------------|---------------------|------------------------------|---------------------|
| aiXplain    | `x-aixplain-key`    | `x-aixplain-key`             | `x-aixplain-key`    |
| Team        | `x-api-key`         | `Authorization: Token <key>` | `x-api-key`         |

The team key header changes from `Authorization: Token` to `x-api-key` to match the Python v2 contract.

### Resolution order (mirrors `core.py`)

```
┌─────────────────────────────┐
│  Explicit apiKey parameter? │──yes──▶ Credential(.teamKey(key))
└──────────┬──────────────────┘
           │ no
           ▼
┌─────────────────────────────┐
│  TEAM_API_KEY env var?      │──yes──▶ Credential(.teamKey(key))
└──────────┬──────────────────┘
           │ no
           ▼
┌─────────────────────────────┐
│  AIXPLAIN_API_KEY env var?  │──yes──▶ Credential(.aixplainKey(key))
└──────────┬──────────────────┘
           │ no
           ▼
        throw AuthError.noCredentialFound
```

## Shared Contracts

| Type | Produced here | Consumed by |
|------|---------------|-------------|
| `AuthenticationScheme` | `Auth/AuthenticationScheme.swift` | RFC-0002 (`AixplainClient` init) |
| `Credential` | `Auth/Credential.swift` | RFC-0002 (`AixplainClient.credential`, `Aixplain` init) |
| `AuthError` | `Errors/AuthError.swift` | RFC-0002 (credential resolution failure), RFC-0005 (`AixplainError.auth` case) |

## Implementation

Clean-slate: delete all v1 auth code and replace with the new types.

### Files to delete

- `Sources/aiXplainKit/Manager/APIKeyManager.swift`
- `Sources/aiXplainKit/Networking/Networking+Metadata.swift`

### Files to create

| File | Content |
|------|---------|
| `Sources/aiXplainKit/Auth/AuthenticationScheme.swift` | `AuthenticationScheme` enum |
| `Sources/aiXplainKit/Auth/Credential.swift` | `Credential` struct with `resolve()` and `authHeaders()` |
| `Sources/aiXplainKit/Errors/AuthError.swift` | `AuthError` enum |

## Testing

- Unit: `Credential.resolve(apiKey: "abc")` returns `.teamKey("abc")`.
- Unit: `Credential.resolve()` with `TEAM_API_KEY` in env returns `.teamKey(...)`.
- Unit: `Credential.resolve()` with `AIXPLAIN_API_KEY` in env returns `.aixplainKey(...)`.
- Unit: `Credential.resolve()` with no key throws `AuthError.noCredentialFound`.
- Unit: `Credential(scheme: .teamKey(""))` throws `AuthError.emptyKey`.
- Unit: `.teamKey` produces header `["x-api-key": key]`.
- Unit: `.aixplainKey` produces header `["x-aixplain-key": key]`.
- Unit: `authHeaders()` always includes `Content-Type: application/json`.

## Out of Scope

- OAuth / token refresh flows (not supported by platform today; Python v2 `enums.py` has `AuthenticationScheme` for integrations, not SDK auth).
- Per-request credential override (deferred to RFC-0002 transport layer).
- API Key CRUD management (`api_key.py` resource) -- will be covered in a future RFC when needed.

## Resolved Questions

1. **`Credential` conforms to `Codable`** -- yes, to support persisted configurations (e.g., saved in UserDefaults or config files).
2. **No `CredentialProvider` protocol** -- credential resolution is handled by `Credential.resolve()` only. No dynamic sources like Keychain.
