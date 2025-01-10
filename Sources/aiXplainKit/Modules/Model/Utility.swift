import Foundation
import OSLog


//TODO: Reafactor, inheritance from model??? 
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
    
    //TODO: Should create  function: Optional[Function] = None,
//    public let cost: TODO: Should create cost
    
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
        
        //TODO: Create task to load code from Model.Version.ID
    }
    
    
    
    func updateCode() async throws{
        if let model = modelInstance{
            //TODO: Try to load code from url in model.version, add code to self.code
        }
    }
    
}

//MARK: Update & Delete
extension UtilityModel{
    
    //TODO: Document
    //return new id
    @discardableResult
    public func update(networking: Networking? = nil) async throws -> String{
        let networking = networking ?? Networking()
        try await updateCode()
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
            return id
        } catch {
            throw ModelError.unableToUpdateModelUtility(error: error.localizedDescription)
        }
    }
    
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

