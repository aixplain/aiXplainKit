//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 12/03/24.
//

import Foundation

///Output provided by a model when calling `Model.run()`
public struct ModelOutput: Codable {
    let output:String
    let usedCredits:Float
    let runtime:TimeInterval
    
    
    enum CodingKeys: String, CodingKey {
        case output = "data"
        case usedCredits
        case runtime = "runTime"
    }
    
    
    // - Throws: DecodingError if there are any issues during decoding.
     public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
         
         output = try container.decode(String.self, forKey: .output)
         usedCredits = try container.decode(Float.self, forKey: .usedCredits)
         runtime = try container.decode(Double.self, forKey: .runtime)

//        id = try container.decode(String.self, forKey: .id)
//        name = try container.decode(String.self, forKey: .name)
//        description = try container.decodeIfPresent(String.self, forKey: .description) ?? "An ML Model"
//        supplier = try container.decode(Supplier.self, forKey: .supplier)
//
//        version = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .version).decodeIfPresent(String.self, forKey: .id) ?? "-"
//
//        pricing = try container.decode(Pricing.self, forKey: .pricing)
//        
//        privacy = nil
//        license = nil
    }
    
    
    
}
