/*
 AiXplainKit Library.
 ---
 
 aiXplain SDK enables Swift programmers to add AI functions
 to their software.
 
 Copyright 2024 The aiXplain SDK authors
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 AUTHOR: João Pedro Maia
 */

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
