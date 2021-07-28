//
//  Codable+Extension.swift
//  FantasmoSDK
//
//

import Foundation

extension Encodable {
    /// - throws `ApiError.requestSerializationFailed(reason:)`
    func toJson() throws -> String {
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(self)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
            else {
                throw ApiError.requestSerializationFailed(reason: .stringSerializationFailed(encoding: .utf8))
            }
        }
        catch {
            throw ApiError.requestSerializationFailed(reason: .jsonEncodingFailed(error: error))
        }
    }
}
