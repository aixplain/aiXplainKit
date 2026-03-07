import Foundation

/// Action metadata from an integration or tool.
///
/// Mirrors Python v2 `Action` dataclass from `integration.py`.
public struct Action: @unchecked Sendable {
    public let name: String?
    public let description: String?
    public let displayName: String?
    public let slug: String?
    public let inputs: [ActionInput]?

    public init(
        name: String? = nil,
        description: String? = nil,
        displayName: String? = nil,
        slug: String? = nil,
        inputs: [ActionInput]? = nil
    ) {
        self.name = name
        self.description = description
        self.displayName = displayName
        self.slug = slug
        self.inputs = inputs
    }

    /// Parse from API response dictionary.
    public static func from(_ dict: [String: Any]) -> Action {
        var inputs: [ActionInput]? = nil
        if let inputList = dict["inputs"] as? [[String: Any]] {
            inputs = inputList.map { ActionInput.from($0) }
        }
        return Action(
            name: dict["name"] as? String,
            description: dict["description"] as? String,
            displayName: dict["displayName"] as? String,
            slug: dict["slug"] as? String,
            inputs: inputs
        )
    }
}

/// Input parameter definition for an action.
///
/// Mirrors Python v2 `Input` dataclass from `integration.py`.
public struct ActionInput: @unchecked Sendable {
    public let name: String
    public var code: String?
    public var datatype: String
    public var allowMulti: Bool
    public var supportsVariables: Bool
    public var defaultValue: [Any]?
    public var required: Bool
    public var fixed: Bool
    public var inputDescription: String

    public init(
        name: String,
        code: String? = nil,
        datatype: String = "string",
        allowMulti: Bool = false,
        supportsVariables: Bool = false,
        defaultValue: [Any]? = nil,
        required: Bool = false,
        fixed: Bool = false,
        inputDescription: String = ""
    ) {
        self.name = name
        self.code = code
        self.datatype = datatype
        self.allowMulti = allowMulti
        self.supportsVariables = supportsVariables
        self.defaultValue = defaultValue
        self.required = required
        self.fixed = fixed
        self.inputDescription = inputDescription
    }

    public static func from(_ dict: [String: Any]) -> ActionInput {
        ActionInput(
            name: dict["name"] as? String ?? "",
            code: dict["code"] as? String,
            datatype: dict["datatype"] as? String ?? "string",
            allowMulti: dict["allowMulti"] as? Bool ?? false,
            supportsVariables: dict["supportsVariables"] as? Bool ?? false,
            defaultValue: dict["defaultValue"] as? [Any],
            required: dict["required"] as? Bool ?? false,
            fixed: dict["fixed"] as? Bool ?? false,
            inputDescription: dict["description"] as? String ?? ""
        )
    }
}
