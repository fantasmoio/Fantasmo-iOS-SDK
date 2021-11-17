//
//  FMDeviceError.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 17.11.21.
//

import Foundation

public enum FMDeviceError: LocalizedError {
    case notSupported
}

extension FMDeviceError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notSupported:
            return "Device not supported."
        }
    }
}
