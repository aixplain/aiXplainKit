import Foundation
import OSLog


//TODO: Reafactor, inheritance from model??? 
public final class UtilityModel: Codable {
    public var id: String
    public let name: String
    public var code: String //TODO: Should improve for either Swift Function or a better representation of Python Code.
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
        
        self.init(id: model.id, name: model.name, code: "unable to display", description: model.description, inputs: inputs, outputExamples: "")
        
        //TODO: Create task to load code from Model.Version.ID
    }
    
}

//MARK: Update & Delete
extension UtilityModel{
    func update(){}//TODO: Complete
    
    func delete(){}//TODO: Delete
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

