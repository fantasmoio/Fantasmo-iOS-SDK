//
//  FMError.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import Foundation

public struct FMError: LocalizedError {
    
    public let type: Error
    public let errorDescription: String?
    public let cause: Error?
    
    init(_ type: Error, errorDescription: String? = nil, cause: Error? = nil) {
        self.type = type
        self.errorDescription = errorDescription ?? type.localizedDescription
        self.cause = cause
    }
    
    init(_ type: Error, _ errorResponse: Data) {
        self.type = type
        do {
            let decoded = try JSONDecoder().decode(ErrorResponse.self, from: errorResponse)
            self.errorDescription = decoded.message
            self.cause = nil
        } catch {
            self.errorDescription = "JSON decoding error"
            self.cause = error
        }
    }
}

extension FMError: CustomStringConvertible {
    public var description: String {
        if let errorDescription = errorDescription {
            return String(describing: type) + " " + errorDescription
        } else {
            return String(describing: type)
        }
    }
}

extension FMError: CustomDebugStringConvertible {
    public var debugDescription: String {
        if let cause = cause {
            return self.description + " caused by " + String(describing: cause)
        } else {
            return self.description
        }
    }
}
