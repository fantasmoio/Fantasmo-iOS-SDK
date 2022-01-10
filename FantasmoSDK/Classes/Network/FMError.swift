//
//  FMError.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import Foundation

public struct FMError {
    
    public let type: Error
    public let cause: Error?
    
    let errorResponse: ErrorResponse?
    
    init(_ type: Error, cause: Error? = nil) {
        self.type = type
        self.cause = cause
        self.errorResponse = nil
    }
    
    init(_ type: Error, _ errorResponse: Data) {
        self.type = type
        self.cause = nil
        self.errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: errorResponse)
    }
}

extension FMError: LocalizedError {
    public var errorDescription: String? {
        if let errorMessage = errorResponse?.message {
            return errorMessage
        } else {
            return String(describing: type)
        }
    }
}

extension FMError: CustomDebugStringConvertible {
    public var debugDescription: String {
        return [String(describing: type), errorResponse?.message, errorResponse?.details, cause?.localizedDescription]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}
