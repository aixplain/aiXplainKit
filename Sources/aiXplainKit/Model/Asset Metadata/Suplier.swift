//
//  Supplier.swift
//
//
//  Created by Joao Pedro Monteiro Maia on 05/03/24.
//

import Foundation

/// Represents a supplier of a asset.
public struct Supplier: Codable {
    /// The unique identifier of the supplier.
      let id: Int

      /// The name of the supplier.
      let name: String

      /// A unique code associated with the supplier.
      let code: String

}
