//
//  FMFrameFilter.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 31.05.2021.
//

import ARKit

public enum FMFilterRejectionReason {
    case cameraPitchTooLow
    case cameraPitchTooHigh
    case movingTooFast
    case movingTooLittle
    
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

public enum FMFrameFilterResult: Equatable {
    case accepted
    case rejected(reason: FMFilterRejectionReason)
}

/// Prime filters are original blocks for compound frame filters or can be used alone as standalone filter.
public protocol FMFrameFilter {
    func accepts(_ frame: ARFrame) -> FMFrameFilterResult
}
