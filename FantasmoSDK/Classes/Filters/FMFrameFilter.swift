//
//  FMFrameFilter.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 31.05.2021.
//

import ARKit

enum FMFrameFilterRejectionReason: CaseIterable {
    case pitchTooLow
    case pitchTooHigh
    case imageTooBlurry
    case imageQualityScoreBelowThreshold
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
        case .insufficientFeatures, .imageQualityScoreBelowThreshold:
            return .panAround
        }
    }
}

enum FMFrameFilterResult: Equatable {
    case accepted
    case rejected(reason: FMFrameFilterRejectionReason)
}

/// Prime filters are original blocks for a compound frame filter or can be used alone as a standalone filter.
protocol FMFrameFilter {
    func accepts(_ frame: FMFrame) -> FMFrameFilterResult
}
