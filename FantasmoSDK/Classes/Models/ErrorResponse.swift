//
//  ErrorResponse.swift
//  FantasmoSDK
//

import Foundation

// MARK: - ErrorResponse
class ErrorResponse: Codable {
    let code: Int
    let message: String?
}
