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
    case movingTooFast
    case movingTooLittle
    case insufficientFeatures
    
    func mapToBehaviorRequest() -> FMBehaviorRequest {
        switch self {
        case .pitchTooLow:
            return .tiltUp
        case .pitchTooHigh:
            return.tiltDown
        case .movingTooFast:
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
    case rejected(reason: FMFrameFilterRejectionReason)
}

protocol FMFrameFilter {
    func accepts(_ frame: FMFrame) -> FMFrameFilterResult
}
