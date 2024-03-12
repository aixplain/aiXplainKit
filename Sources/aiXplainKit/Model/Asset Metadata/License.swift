//
//  License.swift
//
//
//  Created by Joao Pedro Monteiro Maia on 05/03/24.
//

import Foundation

/// A representation of a asset license
public struct License: Codable {
    /// The name of the license.
    let name: String

    /// The unique identifier of the license.
    let identifier: String
}
