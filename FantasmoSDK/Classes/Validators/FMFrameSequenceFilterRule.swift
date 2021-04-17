//
//  FMFrameValidator.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 15.04.2021.
//

import ARKit

protocol FMFrameSequenceFilterRule {
    func check(_ frame: ARFrame) -> Result<Void, FMFrameFilterFailure>
}

enum FMFrameFilterFailure: Error {
    case cameraPitchTooLow
    case cameraPitchTooHigh
    case movingTooFast
    case movingTooLittle
}

extension FMFrameFilterFailure {
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
