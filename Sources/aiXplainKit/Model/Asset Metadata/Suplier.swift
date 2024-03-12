//
//  Supplier.swift
//
//
//  Created by Joao Pedro Monteiro Maia on 05/03/24.
//

import Foundation


/// Represents a supplier of a asset.
public struct Supplier:Codable{
    /// The unique identifier of the supplier.
      let id: Int

      /// The name of the supplier.
      let name: String

      /// A unique code associated with the supplier.
      let code: String
    
    /// Initializes a new `Supplier` struct.
        ///
        /// - Parameters:
        ///   - id: The unique identifier of the supplier.
        ///   - name: The name of the supplier.
        ///   - code: A unique code associated with the supplier.
        init(id: Int, name: String, code: String) {
            self.id = id
            self.name = name
            self.code = code
        }
    
}
