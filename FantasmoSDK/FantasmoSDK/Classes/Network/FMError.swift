//
//  FMError.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import Foundation


/**
 Define enum for different types of errors.
 */
enum FMError {
    case network(type: NetworkError)
    case file(type: Enums.FileError)
    case custom(errorDescription: String?)
    
    class Enums { }
}

extension FMError: FantasmoLocalizedError {
    /**
     Error description for show error messages.
     */
    var errorDescription: String? {
        switch self {
            case .network(let type): return type.localizedDescription
            case .file(let type): return type.localizedDescription
            case .custom(let errorDescription): return errorDescription
        }
    }
}

// MARK: - File Errors

extension FMError.Enums {
    enum FileError {
        case read(path: String)
        case write(path: String, value: Any)
        case custom(errorDescription: String?)
    }
}

extension FMError.Enums.FileError: FantasmoLocalizedError {
    var errorDescription: String? {
        switch self {
            case .read(let path): return "Could not read file from \"\(path)\""
            case .write(let path, let value): return "Could not write value \"\(value)\" file from \"\(path)\""
            case .custom(let errorDescription): return errorDescription
        }
    }
}

enum NetworkError: FantasmoLocalizedError {
    
    case errorString(String)
    case custom(code: Double?, message: String)
    case generic
    case parsing
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .errorString(let errorMessage): return errorMessage
        case .custom(_,let message): return message
        case .generic: return Errors.genericError
        case .parsing: return "Parsing error"
        case .notFound: return "URL Not Found"
        }
    }
    
    var info: (code: Double?, message: String) {
        switch self {
        case .custom(let code, let message):
            return (code, message)
        case .errorString(let errorMessage):
            return (nil, errorMessage)
        case .generic,
             .parsing:
            return (nil, Errors.genericError)
        case .notFound:
            return (404, Errors.genericError)
        }
    }
}

protocol FantasmoLocalizedError: LocalizedError {
    var title: String { get }
    var localDescription: String { get }
}

extension FantasmoLocalizedError {
    var title: String {
        return ""
    }
    
    var localDescription : String {
        return ""
    }
}

struct Errors {
    static let genericError = "Something went wrong. Please try again."
    static let networkUnreachableError  = "No internet connection. Please try again later."
}
