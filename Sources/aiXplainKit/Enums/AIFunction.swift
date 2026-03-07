import Foundation

/// AI functions supported by the platform.
///
/// Mirrors Python v2 `Function` enum from `enums.py`.
public enum AIFunction: String, Codable, Sendable {
    case search = "SEARCH"
    case translation = "TRANSLATION"
    case sentimentAnalysis = "SENTIMENT_ANALYSIS"
    case classification = "CLASSIFICATION"
    case questionAnswering = "QUESTION_ANSWERING"
    case textGeneration = "TEXT_GENERATION"
    case speechRecognition = "SPEECH_RECOGNITION"
    case imageClassification = "IMAGE_CLASSIFICATION"
    case objectDetection = "OBJECT_DETECTION"
    case utilities
}
