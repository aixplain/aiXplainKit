//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 05/03/24.
//

import Foundation

/// Represents the pricing information for an given Asset.
public struct Pricing: Codable {
    /// The price of the asset
    let price: Float

    /// The unit of measurement for the price (e.g., "USD", "EUR", "TOKENS").
    let unitType: String

    /// The scale of the unit (e.g., "micro", "milli").
    let unitScale: String?

    /// Initializes a new `Pricing` struct.
    ///
    /// - Parameters:
    ///   - price: The price of the given asset.
    ///   - unit: The unit of measurement for the price.
    ///   - unitScale: The scale of the unit (optional).
    init(price: Float, unitType: String, unitScale: String? = nil) {
        self.price = price
        self.unitType = unitType
        self.unitScale = unitScale
    }

}
