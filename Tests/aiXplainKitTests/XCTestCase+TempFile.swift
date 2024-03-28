//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 26/03/24.
//

import Foundation
import XCTest

extension XCTestCase {
    func withTempFile(from url: URL, _ completion: @escaping (URL) async -> Void) async {
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(url.lastPathComponent)

        do {
            let data = try await downloadData(from: url)
            try data.write(to: temporaryFileURL)

            await completion(temporaryFileURL)

            do {
                try FileManager.default.removeItem(at: temporaryFileURL)
            } catch {
                XCTFail("Error removing file: \(error.localizedDescription)")
            }

        } catch {
            XCTFail("Error downloading file: \(error.localizedDescription)")
        }
    }

    private func downloadData(from url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}
