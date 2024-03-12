//
//  FileManager.swift
//
//
//  Created by Joao Pedro Monteiro Maia on 12/03/24.
//

import Foundation

/// This class is responable for managing the files send to the model. It deals with uploading and all sorts of stuff related to files TODO: Improve this
internal final class AiXplainFileManager {

    let networking: Networking = Networking()

    let logger = ParrotLogger(category: "AiXplainKit | FileManager")

    func uploadFile(at localUrl: URL, temporary: Bool = true, tags: [String: String] = [:], license: License? = nil) async throws {
        if try FileSizeLimit.check(fileAt: localUrl) == false {
            throw FileError.fileToLarge
        }

//        let headers: [String: String] = try networking.buildHeader()
//        var payload: [String: String] = [:]
//
//        guard let url = APIKeyManager.shared.BACKEND_URL else {
//            throw ModelError.missingBackendURL
//        }
//
//        let endpoint = Networking.Endpoint.fileUpload(isTemporary: temporary)
//        guard let url = URL(string: url.absoluteString + endpoint.path) else {
//            throw ModelError.invalidURL(url: url.absoluteString + endpoint.path)
//        }
//        
//        if temporary{
//            payload = ["contentType": contentType, "originalName": localUrl.lastPathComponent]
//        }
////        else{
////            payload = {"contentType": content_type, "originalName": file_name, "tags": ",".join(tags), "license": license.value}
////        }
//        
//        
//        let response = try await networking.post(url: url, headers: headers)

    }

    private func isFileAllowed(_ localURL: URL) -> Bool {
        let MB_1 = 1048576
        let MB_25 = 26214400
        let MB_50 = 52428800
        let MB_300 = 314572800

        let maxSize = ["audio": MB_50, "application": MB_25, "video": MB_300, "image": MB_25, "other": MB_50]

        return true
    }

}
