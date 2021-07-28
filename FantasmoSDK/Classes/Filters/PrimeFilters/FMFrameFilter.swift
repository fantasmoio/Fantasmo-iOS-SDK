//
//  FMFrameFilter.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 31.05.2021.
//

import ARKit

public enum FMFilterRejectionReason: CaseIterable {
    case cameraPitchTooLow
    case cameraPitchTooHigh
    case movingTooFast
    case movingTooLittle
    /// The scene visible to the camera doesn't contain enough distinguishable features for image-based position tracking.
    case insufficientFeatures
    case unknown

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
        case .insufficientFeatures:
            return .panAround
        case .unknown:
            return .reportAboutProblem
        }
    }
}

public enum FMFrameFilterResult: Equatable {
    case accepted
    case rejected(reason: FMFilterRejectionReason)
}

/// Prime filters are original blocks for a compound frame filter or can be used alone as a standalone filter.
public protocol FMFrameFilter {
    func accepts(_ frame: ARFrame) -> FMFrameFilterResult
}
