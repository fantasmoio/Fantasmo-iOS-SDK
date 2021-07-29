//
//  Codable+Extension.swift
//  FantasmoSDK
//
//

import Foundation

private var emptyJsonObject: String = "{}"

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
                return emptyJsonObject
            }
        }
        catch {
            throw ApiError.requestSerializationFailed(reason: .jsonEncodingFailed(error: error))
        }
    }
}



