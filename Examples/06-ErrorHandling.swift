/// # Error Handling
///
/// How to handle errors from the aiXplain SDK.

import aiXplainKit

@main
struct ErrorHandlingExample {
    static func main() async throws {
        // --- Credential errors ---
        do {
            _ = try Credential(scheme: .teamKey(""))
        } catch let error as AuthError {
            print("Auth error: \(error.errorDescription ?? "")")
            // "API key must not be empty."
        }

        do {
            _ = try Credential.resolve(environment: [:])
        } catch let error as AuthError {
            print("Auth error: \(error.errorDescription ?? "")")
            // "API key is required. Pass it as an argument or set the TEAM_API_KEY environment variable."
        }

        // --- API errors with the unified error type ---
        let aix = try Aixplain()
        do {
            _ = try await Agent.get("nonexistent-agent-id", context: aix)
        } catch let error as AixplainError {
            switch error {
            case .auth(let authError):
                print("Authentication failed: \(authError)")
            case .api(let apiError):
                print("API error [\(apiError.statusCode)]: \(apiError.message)")
                if let rid = apiError.requestId {
                    print("  Request ID: \(rid)")
                }
                // User-friendly message for UI
                print("  User message: \(apiError.userMessage)")
            case .validation(let valError):
                print("Validation: \(valError.message)")
            case .timeout(let timeoutError):
                print("Timeout: \(timeoutError.message)")
                if let url = timeoutError.pollingURL {
                    print("  Polling URL: \(url)")
                }
            case .fileUpload(let uploadError):
                print("Upload failed: \(uploadError.message)")
            case .resource(let resourceError):
                print("Resource error: \(resourceError.message)")
            }

            // Or use the unified userMessage
            print("User-facing: \(error.userMessage)")
        }

        // --- Validation before requests ---
        let agent = Agent(name: "Test")
        do {
            try agent.ensureValidState()
        } catch {
            print("Expected: \(error)") // Agent not saved yet
        }
    }
}
