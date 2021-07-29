//
//  MultipartFormData+Utils.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 29.07.2021.
//

import Foundation

extension MultipartFormData {
    
    /// Multipart form data boundary expected by Fantasmo API server.
    static var specificBoundary: String { "ce8f07c0c2d14f0bbb1e3a96994e0354" }
    
    /// - throws `ApiError.requestSerializationFailed` in case of failure
    func appendParameters(_ params: [String : Any]) throws {
        for (key, value) in params {
            let stringValue: String
            
            if let aValue = value as? String {
                stringValue = aValue
            }
            else if let aValue = value as? Encodable {
                do {
                    stringValue = try aValue.toJson()
                }
                catch {
                    throw ApiError.requestSerializationFailed(reason: .jsonEncodingFailed(error: error))
                }
            }
            else {
                let msg = "Parameter with key = \(key) and value = \(value) cannot be added to `MultipartFormData`"
                throw ApiError.requestSerializationFailed(reason: .jsonEncodingFailed(msg: msg))
            }
            append(stringValue.data(using: .utf8)!, withName: key)
        }
    }
    
}
