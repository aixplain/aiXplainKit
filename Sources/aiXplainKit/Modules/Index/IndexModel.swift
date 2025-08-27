//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 12/05/25.
//

import Foundation

public class IndexModel:Model {
    public override init(id: String, name: String, description: String, supplier: Supplier, version: Version? = nil, license: License? = nil, privacy: Privacy? = nil, pricing: Pricing, hostedBy: String, developedBy: String, networking: Networking) {
        super.init(id: id, name: name, description: description, supplier: supplier, pricing: pricing, hostedBy: hostedBy, developedBy: developedBy, networking: networking)
    }
    
    public init?(from model: Model, bypass: Bool = false){
        if model.function?.id != "search" || bypass {
            return nil
        }
        super.init(id: model.id, name: model.name, description: model.description, supplier: model.supplier, pricing: model.pricing, hostedBy: model.hostedBy, developedBy: model.developedBy, networking: model.networking)
    }
    
    
    required public init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    
    
}

//MARK: - Index model operations
extension IndexModel{
    /// Searches textual records using the provided full-text `query`.
    ///
    /// - Parameters:
    ///   - query:     The free-form text that will be matched against the indexed
    ///                corpus.
    ///   - top_k:     The maximum amount of results to be returned. Defaults to
    ///                `10`. **Note**: The underlying service expects the snake-
    ///                cased key `top_k`, therefore the parameter label is kept
    ///                as-is to avoid further transformations.
    ///   - filters:   Optional metadata filters that will be applied server-side
    ///                before the similarity computation.
    /// - Returns: A fully decoded `IndexSearchOutput` instance.
    /// - Throws:  `NetworkingError` or `ModelError` if any step in the execution
    ///            pipeline fails.
    public func search(_ query:String, top_k:Int = 10, filters:[IndexFilter] = []) async throws -> IndexSearchOutput{
        
        //TODO: Images
        
        
        let data:[String:Any] = [
            "action" : "search",
            "data" : query,
            "data_type" : "text",
            "filters": filters.map({$0.toDict()}), //This created a list of [string:string]
            "payload": [
                "uri" : "",
                "top_k" : top_k,
                "value_type" : "text"
            ]
        ]
        
        // JSONEncoder can't handle `[String: Any]`; use `JSONSerialization` instead
        let encodedData = try JSONSerialization.data(withJSONObject: data, options: [])
        
        
        return try await self.runSearch(encodedData)
        
    }
    
    /// Searches image records using the image located at `query`.
    ///
    /// The image will be uploaded to the aiXplain storage bucket first (if not
    /// already hosted) and subsequently used as the search anchor.
    ///
    /// - Parameters:
    ///   - query:   The local **file** `URL` of the image or a remote `URL`
    ///              previously uploaded.
    ///   - top_k:   The maximum amount of results to be returned. Defaults to
    ///              `10`.
    ///   - filters: Optional metadata filters.
    ///
    /// - Throws: `ModelError.invalidURL` if the provided URL does not reference
    ///           an image; any error thrown by `FileUploadManager` or the
    ///           networking layer.
    public func search(_ query:URL, top_k:Int = 10, filters:[IndexFilter] = []) async throws -> IndexSearchOutput{
        
        guard query.mimeType().hasPrefix("image/") else {
            throw ModelError.invalidURL(url: query.absoluteString)
        }
        
        let fileLink = try await FileUploadManager().uploadDataIfNeedIt(from: query)
        
        
        
        let data:[String:Any] = [
            "action" : "search",
            "data" : "",
            "data_type" : "image",
            "filters": filters.map({$0.toDict()}), //This created a list of [string:string]
            "payload": [
                "uri" : fileLink.absoluteString,
                "top_k" : top_k,
                "value_type" : "image"
            ]
        ]
        
        
        // JSONEncoder can't handle `[String: Any]`; use `JSONSerialization` instead
        let encodedData = try JSONSerialization.data(withJSONObject: data, options: [])
        
        
        return try await self.runSearch(encodedData)
        
    }
    
    
//    upsert documents, return true if succed, TODO: Better docs
    @discardableResult
    public func upsert(_ documents: [Record]) async throws ->Bool{
       
        let payload:[String:ModelInput] = ["action": "ingest", "data": documents]
        let result = try await self.run(payload)
        
        return result.output == "success"
    }
    
    
    public func get(documentID:String) async throws ->Record?{
        
        let data:[String:ModelInput] = ["action": "get_document", "data": documentID]
        let response = try await  self.run(data)
        
        #if DEBUG
        debugPrint("[aiXplainKit] get(documentID:) response ->", response)
        #endif
        if response.output.isEmpty{
            return nil
        }
        return Record(text: response.output,id: documentID)
    }
    
//Count how many objects in this index
    public func count() async throws ->Int{
        let  data:[String:ModelInput] = ["action": "count", "data": ""]
        let response = try await self.run(data)
        return Int(response.output) ?? -1
    }
    
    
}


//MARK: Swifty features
extension IndexModel{
//    Cannot find type 'async' in scope
    public subscript(id: String) -> Record? {
        get async throws {
            try await self.get(documentID: id)
        }
    }
}


//MARK: Index Model Custom Model run
extension IndexModel{
    
    //This is a custom run method only used in search functions
    private func runSearch(_ data:Data) async throws ->IndexSearchOutput{
        let headers = try self.networking.buildHeader()
        let payload = data
        guard let url = APIKeyManager.shared.MODELS_RUN_URL else {
            throw ModelError.missingModelRunURL
        }

        guard let url = URL(string: url.absoluteString + self.id) else {
            throw ModelError.invalidURL(url: url.absoluteString)
        }


       
        let response = try await networking.post(url: url, headers: headers, body: payload)

        if let httpUrlResponse = response.1 as? HTTPURLResponse,
           httpUrlResponse.statusCode != 201 {
            throw NetworkingError.invalidStatusCode(statusCode: httpUrlResponse.statusCode)
        }

        let decodedResponse = try JSONDecoder().decode(ModelExecuteResponse.self, from: response.0)

        guard let pollingURL = decodedResponse.pollingURL else {
            throw ModelError.failToDecodeRunResponse
        }

        return try await pollingSearch(from: pollingURL)
    }
    
    
    
    private func pollingSearch(from url: URL, maxRetry: Int = 300, waitTime: Double = 0.5) async throws -> IndexSearchOutput {
        let headers = try self.networking.buildHeader()

        var itr = 0


        repeat {
            let response = try await networking.get(url: url, headers: headers)

            if let json = try? JSONSerialization.jsonObject(with: response.0, options: []) as? [String: Any],
               let completed = json["completed"] as? Bool {

                if let _ = json["error"] as? String, let supplierError = json["supplierError"] as? String {
                    throw ModelError.supplierError(error: supplierError)
                }

                if completed {
                    do {
                        let decodedResponse = try JSONDecoder().decode(IndexSearchOutput.self, from: response.0)
                        return decodedResponse
                    } catch {
                        throw ModelError.failToDecodeModelOutputDuringPollingPhase(error: String(describing: error))
                    }
                }
            }

            try await Task.sleep(nanoseconds: UInt64(max(0.2, waitTime) * 1_000_000_000))
            itr+=1
        } while itr < maxRetry

        throw ModelError.pollingTimeoutOnModelResponse(pollingURL: url)
    }
    
    
    
}
