//
//  FMLocationError.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 07.10.21.
//

import Foundation

public enum FMLocationError: LocalizedError {
    case accessDenied
    case invalidCoordinate
}

extension FMLocationError {
    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "No location access."
        case .invalidCoordinate:
            return "Invalid location coordinate."
        }
    }
}
