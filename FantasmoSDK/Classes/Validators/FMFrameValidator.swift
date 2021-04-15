//
//  FMFrameValidator.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 15.04.2021.
//

import ARKit

protocol FMFrameValidator {
    func validate(_ frame: ARFrame) -> Result<Void, FMFrameValidationError>
}

enum FMFrameValidationError: Error {
    case cameraPitchTooLow
    case cameraPitchTooHigh
    case movingTooFast
    case movingTooLittle
}

extension FMFrameValidationError {
    func mapToBehaviorRequest() -> FMBehaviorRequest {
        switch self {
        case .cameraPitchTooLow:
            return .tiltUp
        case .cameraPitchTooHigh:
            return.tiltDown
        case .movingTooFast:
            return .panSlowly
        case .movingTooLittle:
            return .panAround
        }
    }
}
