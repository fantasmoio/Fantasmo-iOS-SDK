//
//  ErrorResponse.swift
//  FantasmoSDK
//

import Foundation

// MARK: - ErrorResponse
class ErrorResponse: Decodable {
    let code: Int
    let message: String?

    enum CodingKeys: String, CodingKey {
        case code
        case statusCode
        case message
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let statusCode = try values.decodeIfPresent(Int.self, forKey: .code) {
            code = statusCode
        } else if let statusCode = try values.decodeIfPresent(Int.self, forKey: .statusCode) {
            code = statusCode
        } else {
            code = 0
        }
        message = try values.decodeIfPresent(String.self, forKey: .message)
    }
}
