//
//  Data+Extension.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 28.07.2021.
//

import Foundation

/// Multipart form extension
/// Provides methods required for preparing data for a `multipart/form-data` transaction
extension Data {
    static let crlf = "\r\n"
    static let crlf2x = crlf + crlf
    static let boundary = "ce8f07c0c2d14f0bbb1e3a96994e0354"

    enum BoundaryType {
        case initial, middle, final
    }
    
    static func boundaryData(_ type: BoundaryType) -> Data {
        let boundaryText: String
        
        switch type {
        case .initial:
            boundaryText = "--\(boundary)\(crlf)"
        case .middle:
            boundaryText = "\(crlf)--\(boundary)\(crlf)"
        case .final:
            boundaryText = "\(crlf)--\(boundary)--\(crlf)"
        }
        
        return Data(boundaryText.utf8)
    }
    
    /// - throws `ApiError.requestSerializationFailed` in case of failure
    mutating func appendParameters(_ params: [String : Any]) throws {
        for (key, value) in params {
            let stringValue: String
            if let val = value as? String {
                stringValue = val
            }
            else if let val = value as? Encodable {
                do {
                    stringValue = try val.toJson()
                }
                catch {
                    throw ApiError.requestSerializationFailed(reason: .jsonEncodingFailed(error: error))
                }
            }
            else {
                throw ApiError.requestSerializationFailed(reason: .jsonEncodingFailed(msg: "\(value) is not `Encodable`"))
            }
            self.appendParameter(key, value: stringValue)
        }
    }
    
    mutating func appendParameter(_ name: String, value: String) {
        self.append(Self.boundaryData(.middle))
        self.append("Content-Disposition: form-data; name=\"\(name)\"\(Self.crlf2x)".data(using: .utf8)!)
        self.append(value.data(using: .utf8)!)
    }
    
    mutating func appendImage(_ imageData: Data) {
        self.append(Self.boundaryData(.middle))
        self.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\(Self.crlf)".data(using: .utf8)!)
        self.append("Content-Type: image/jpeg\(Self.crlf2x)".data(using: .utf8)!)
        self.append(imageData)
    }
    
    mutating func appendFinalBoundary() {
        self.append(Self.boundaryData(.final))
    }
}
