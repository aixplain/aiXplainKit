//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 05/03/24.
//

import Foundation

/// Represents the different privacy levels of assets.
public enum Privacy:String,Codable{
    /// Publicly accessible asset.
    case PUBLIC
    
    /// Private asset, not accessible to the public.
    case PRIVATE
    
    /// Asset with restricted access, requiring specific permissions.
    case RESTRICTED
}
