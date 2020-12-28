//
//  Codable+Extension.swift
//  FantasmoSDK
//
//

import Foundation

extension Encodable {
    func toJson() -> String {
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(self)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch { }
        return "{}"
    }
}
