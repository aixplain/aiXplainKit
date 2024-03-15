//
//  Asset.swift
//
//
//  Created by Joao Pedro Monteiro Maia on 05/03/24.
//

import Foundation

/// A protocol defining the basic information for an asset
protocol Asset {
    /// The unique identifier of the asset.
    var id: String { get }

    /// The name of the asset.
    var name: String { get }

    /// A description of the asset's purpose and functionality.
    var modelDescription: String { get }

    /// The supplier of the asset, providing information about its source.
    var supplier: Supplier { get }

    /// The version of the asset.
    var version: String {get}

    /// The license information associated with the asset, if applicable.
    var license: License? { get }

    /// The privacy level of the asset.
    var privacy: Privacy? { get }

    /// The pricing information for using the asset.
    var pricing: Pricing { get }
}

/// A protocol for assets that can be encoded and decoded using the `Codable` protocol.
protocol CodableAsset: Asset, Codable {}

/// A protocol for assets that can be encoded using the `Encodable` protocol.
protocol EncodableAsset: Asset, Encodable {}

/// A protocol for assets that can be decoded using the `Decodable` protocol.
protocol DecodableAsset: Asset, Decodable {}
