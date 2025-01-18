import Foundation
import OSLog



public final class UtilityModel: Codable {
    public var id: String
    public let name: String
    public var code: String
    public var description: String
    public var inputs: [UtilityModelInputInformation]
    public var outputExamples: String
    public let supplier: Supplier?
    public let version: String?
    public let isSubscribed: Bool = false
    private var modelInstance:Model?
    
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case inputs
        case code
        case outputExamples = "outputDescription"
        case supplier
        case version
        case isSubscribed
    }
    

    
    init(id: String, name: String, code: String, description: String, inputs: [UtilityModelInput], outputExamples: String, supplier: Supplier? = nil, version: String? = nil) {
        self.id = id
        self.name = name
        self.code = code
        self.description = description
        self.inputs = inputs.map{$0.encode()}
        self.outputExamples = outputExamples
        self.supplier = supplier
        self.version = version
    }
    
    init(id: String, name: String, code: String, description: String, inputs: [UtilityModelInputInformation], outputExamples: String, supplier: Supplier? = nil, version: String? = nil) {
        self.id = id
        self.name = name
        self.code = code
        self.description = description
        self.inputs = inputs
        self.outputExamples = outputExamples
        self.supplier = supplier
        self.version = version
    }
    
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        inputs = try container.decode([UtilityModelInputInformation].self, forKey: .inputs)
        code = try container.decode(String.self, forKey: .code)
        outputExamples = try container.decode(String.self, forKey: .outputExamples)
        supplier = try container.decodeIfPresent(Supplier.self, forKey: .supplier)
        version = try container.decodeIfPresent(String.self, forKey: .version)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(inputs, forKey: .inputs)
        try container.encode(code, forKey: .code)
        try container.encode(outputExamples, forKey: .outputExamples)
    }
    
    
    public convenience init(from model: Model){
        var inputs:[UtilityModelInputInformation] = []
        
        model.parameters.forEach{ param in
            inputs.append(UtilityModelInputInformation(name: param.name, description: "", type: UtilityModelInputType(rawValue: param.dataType) ?? .text))
        }
        
        self.init(id: model.id, name: model.name, code: "", description: model.description, inputs: inputs, outputExamples: "")
        
        self.modelInstance = model
        
        Task{
            try await updateCode()
        }
    }
    
    
    
    public func updateCode() async throws -> String?{
        if let model = modelInstance,
           let versionUrl = URL(string: model.version) {
            let (data, response) = try await URLSession.shared.data(from: versionUrl)
            
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                throw NetworkingError.invalidStatusCode(statusCode: httpResponse.statusCode)
            }
            
            if let codeString = String(data: data, encoding: .utf8) {
                self.code = codeString
                return codeString
            }
            
            return nil
        }
        return nil
    }
    
    public func updateModelInstance() async throws{
        self.modelInstance = try await ModelProvider().get(self.id)
    }
    
}

//MARK: Update & Delete
extension UtilityModel{
    
    /// Updates the utility model on the server with its current state.
    ///
    /// This method synchronizes the current state of the utility model with the server by:
    /// 1. Updating the code from the model version URL
    /// 2. Encoding the model into JSON
    /// 3. Sending a PUT request to update the server
    /// 4. Updating the local ID with the response
    ///
    /// - Parameter networking: Optional networking instance to use. If nil, creates a new one.
    /// - Returns: The ID of the updated utility model
    /// - Throws: 
    ///   - `ModelError.missingBackendURL` if the backend URL is not configured
    ///   - `ModelError.invalidURL` if the constructed URL is invalid
    ///   - `NetworkingError.invalidStatusCode` if response status code is not 2xx
    ///   - `ModelError.unableToUpdateModelUtility` if response decoding fails
    ///
    /// # Example
    /// ```swift
    /// do {
    ///     let newId = try await utilityModel.update()
    ///     print("Model updated with ID: \(newId)")
    /// } catch {
    ///     print("Failed to update model: \(error)")
    /// }
    /// ```
    @discardableResult
    public func update(networking: Networking? = nil) async throws -> String{
        let networking = networking ?? Networking()
        if code.isEmpty{
            try await self.updateCode()
        }
        let headers = try networking.buildHeader()
        
        guard let url = APIKeyManager.shared.BACKEND_URL else {
            throw ModelError.missingBackendURL
        }

        let endpoint = Networking.Endpoint.utilities.path
        guard let url = URL(string: url.absoluteString + endpoint + "/" + self.id) else {
            throw ModelError.invalidURL(url: url.absoluteString)
        }
        
        let payload = try JSONEncoder().encode(self)

        let response = try await networking.put(url: url, body: payload, headers: headers)

        if let httpUrlResponse = response.1 as? HTTPURLResponse,
           !(200...299).contains(httpUrlResponse.statusCode) {
            throw NetworkingError.invalidStatusCode(statusCode: httpUrlResponse.statusCode)
        }

        struct IDResponse: Codable {
            let id: String
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(IDResponse.self, from: response.0)
            self.id = decodedResponse.id
            self.modelInstance = try await ModelProvider().get(self.id)
            return id
        } catch {
            throw ModelError.unableToUpdateModelUtility(error: error.localizedDescription)
        }
    }
    
    /// Deletes the utility model from the server.
    ///
    /// This method sends a DELETE request to remove the utility model from the aiXplain platform.
    /// Once deleted, the model cannot be recovered.
    ///
    /// - Parameter networking: Optional networking instance for making the request. If nil, creates a new instance.
    ///
    /// - Throws:
    ///   - `ModelError.missingBackendURL` if the backend URL is not configured
    ///   - `ModelError.invalidURL` if the constructed URL is invalid
    ///   - `NetworkingError.invalidStatusCode` if response status code is not 2xx
    ///   - `ModelError.unableToUpdateModelUtility` if response decoding fails
    ///
    /// # Example
    /// ```swift
    /// do {
    ///     try await utilityModel.delete()
    ///     print("Model successfully deleted")
    /// } catch {
    ///     print("Failed to delete model: \(error)")
    /// }
    /// ```
    public func delete(networking: Networking? = nil) async throws{
        let networking = networking ?? Networking()
        let headers = try networking.buildHeader()
        
        guard let url = APIKeyManager.shared.BACKEND_URL else {
            throw ModelError.missingBackendURL
        }

        let endpoint = Networking.Endpoint.utilities.path
        guard let url = URL(string: url.absoluteString + endpoint + "/" + self.id) else {
            throw ModelError.invalidURL(url: url.absoluteString)
        }
        

        let response = try await networking.delete(url: url, headers: headers)

        if let httpUrlResponse = response.1 as? HTTPURLResponse,
           !(200...299).contains(httpUrlResponse.statusCode) {
            throw NetworkingError.invalidStatusCode(statusCode: httpUrlResponse.statusCode)
        }
        
        struct IDResponse: Codable {
            let id: String
        }

        do {
            let decodedResponse = try JSONDecoder().decode(IDResponse.self, from: response.0)
            self.id = decodedResponse.id

        } catch {
            throw ModelError.unableToUpdateModelUtility(error: error.localizedDescription)
        }
    }
}

//MARK: Utility Model Execution
extension UtilityModel{
    /// Executes the utility model with the given input and parameters.
    ///
    /// This method runs the model either using a cached instance or by fetching a new instance from the server.
    ///
    /// - Parameters:
    ///   - modelInput: The input data to process
    ///   - id: Optional identifier for the model process (defaults to "model_process")
    ///   - parameters: Optional run parameters (defaults to .defaultParameters)
    ///
    /// - Returns: A ModelOutput containing the results of the model execution
    ///
    /// - Throws:
    ///   - `ModelError.failToCallModelExecuteFromUtility` if the model execution fails
    ///
    /// # Example
    /// ```swift
    /// do {
    ///     let input = ModelInput(/* input parameters */)
    ///     let output = try await utilityModel.run(input)
    ///     print("Model execution successful")
    /// } catch {
    ///     print("Model execution failed: \(error)")
    /// }
    /// ```
    public func run(_ modelInput: ModelInput, id: String = "model_process", parameters: ModelRunParameters = .defaultParameters) async throws -> ModelOutput {
        if let model = modelInstance {
            return try await model.run(modelInput, id:id, parameters: parameters)
        }
        do {
            let model = try await ModelProvider().get(self.id)
            self.modelInstance = model
            return try await model.run(modelInput, id:id, parameters: parameters)
        }catch {
            throw ModelError.failToCallModelExecuteFromUtility(error: error.localizedDescription)
        }
    }
    
}

