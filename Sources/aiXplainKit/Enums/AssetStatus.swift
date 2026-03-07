import Foundation

/// Asset status values shared across all resources (Agent, Model, Tool).
///
/// Mirrors Python v2 `AssetStatus` enum from `enums.py`.
public enum AssetStatus: String, Codable, Sendable {
    case draft
    case hidden
    case scheduled
    case onboarding
    case onboarded
    case pending
    case failed
    case training
    case rejected
    case enabling
    case deleting
    case disabled
    case deleted
    case inProgress = "in_progress"
    case completed
    case canceling
    case canceled
    case deprecatedDraft = "deprecated_draft"
}
