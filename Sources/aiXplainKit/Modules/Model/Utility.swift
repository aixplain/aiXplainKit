import Foundation
import OSLog


//TODO: Reafactor, inheritance from model??? 
public final class UtilityModel: Codable {
    public var id: String
    public let name: String
    public var code: String //TODO: Should improve for either Swift Function or a better representation of Python Code.
    public var description: String
    public var inputs: [UtilityModelInput]
    public var outputExamples: String
    public let supplier: Supplier?
    public let version: String?
    public let isSubscribed: Bool = false
    
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
        inputs = try container.decode([UtilityModelInput].self, forKey: .inputs)
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


    func update(){}//TODO: Complete
    
    func delete(){}//TODO: Delete
    
}
