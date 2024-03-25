//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 19/03/24.
//

import Foundation

enum PipelineError: Error, Equatable {
    /// No API key was provided for making API calls.
    case missingAPIKey

    /// No backend URL was provided for the backend service.
    case missingBackendURL

    /// The provided URL is malformed.
    case invalidURL(url: String?)

    /// Error during the recoding of model.run response while schedulling the run.
    case failToDecodeRunResponse

    /// This error is thrown when the model is polling the response for the job created at `Model.run` did not receive a response/output in the desired time.
    case pollingTimeoutOnModelResponse(pollingURL: URL)

    /// Fail to decode ModelOutput during the polling phase.
    case failToDecodeModelOutputDuringPollingPhase(error: String?)

    /// Error reported by the supplier or service.
    case supplierError(error: String)

    /// An unsupported value type was encountered during input payload generation.
    case typeNotRecognizedWhileCreatingACombinedInput

    /// An error occurred during input encoding.
    case inputEncodingError

    var localizedDescription: String {
        switch self {
        case .missingAPIKey:
            return "No API key was provided to make API calls. Please set a key using `AiXplainKit.keyManager`."
        case .missingBackendURL:
            return "No URL was provided for the backend service. Please set a URL using `AiXplainKit.keyManager`."
        case .invalidURL(let url):
            guard let url = url else { return "Invalid URL." }
            return "The provided URL is malformed: \(url)"
        case .failToDecodeRunResponse:
            return "Error during the recoding of model.run response while schedulling the run."
        case .pollingTimeoutOnModelResponse(pollingURL: let pollingURL):
            return "The model did not respond with the output within the expected time during the polling phase. You can try to get the data by the following URL: \(pollingURL.absoluteString)"
        case .failToDecodeModelOutputDuringPollingPhase(error: let error):
            return "An error occurred while decoding the model output during the polling phase." + (error.map { " Details: \($0)" } ?? "")
        case .supplierError(let error):
            return "An error ocurred from the suplier side: \(error)."
        case .typeNotRecognizedWhileCreatingACombinedInput:
            return "An unsupported value type was encountered during input payload generation. Please ensure that all input values are either URLs or strings."
        case .inputEncodingError:
            return "An error occurred during input encoding. Please check the input data and try again."
        }
    }
}
