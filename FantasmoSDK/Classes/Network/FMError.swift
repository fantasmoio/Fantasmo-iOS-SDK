//
//  FMError.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import Foundation

struct FMError: LocalizedError {
    enum ErrorType: Error {
        case errorResponse
        case invalidErrorResponse
    }
    
    var type: Error
    var errorDescription: String?
    var cause: Error?
    
    init(_ type: Error, errorDescription: String? = nil, cause: Error? = nil) {
        self.type = type
        self.errorDescription = errorDescription
        self.cause = cause
    }
    
    init(_ errorResponse: Data) {
        do {
            let decoded = try JSONDecoder().decode(ErrorResponse.self, from: errorResponse)
            self.type = ErrorType.errorResponse
            self.errorDescription = decoded.message
        } catch {
            self.type = ErrorType.invalidErrorResponse
            self.errorDescription = "JSON decoding error"
            self.cause = error
        }
    }
}

extension FMError: CustomStringConvertible {
    var description: String {
        return "Error: " + type.localizedDescription + " " + (errorDescription ?? "")
    }
}

extension FMError: CustomDebugStringConvertible {
    var debugDescription: String {
        return self.description + cause.debugDescription
    }
}
