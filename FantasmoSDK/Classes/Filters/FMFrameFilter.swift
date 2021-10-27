//
//  FMFrameFilter.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 31.05.2021.
//

import ARKit

enum FMFilterRejectionReason: CaseIterable {
    case pitchTooLow
    case pitchTooHigh
    case imageTooBlurry
    case movingTooFast
    case movingTooLittle
    case insufficientFeatures
    
    func mapToBehaviorRequest() -> FMBehaviorRequest {
        switch self {
        case .pitchTooLow:
            return .tiltUp
        case .pitchTooHigh:
            return.tiltDown
        case .movingTooFast, .imageTooBlurry:
            return .panSlowly
        case .movingTooLittle:
            return .panAround
        case .insufficientFeatures:
            return .panAround
        }
    }
}

enum FMFrameFilterResult: Equatable {
    case accepted
    case rejected(reason: FMFilterRejectionReason)
}

/// Prime filters are original blocks for a compound frame filter or can be used alone as a standalone filter.
protocol FMFrameFilter {
    func accepts(_ frame: FMFrame) -> FMFrameFilterResult
}
