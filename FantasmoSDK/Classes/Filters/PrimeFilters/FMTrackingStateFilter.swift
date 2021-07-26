//
//  FMTrackingStateFilter.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 23.07.2021.
//

import ARKit

struct FMTrackingStateFilter: FMFrameFilter {
    
    func accepts(_ frame: ARFrame) -> FMFrameFilterResult {
        switch frame.camera.trackingState {
        case .normal:
            return .accepted
        case .limited(let reason):
            switch reason {
            case .initializing:
                return .rejected(reason: .movingTooLittle)
            case .relocalizing:
                return .rejected(reason: .movingTooLittle)
            case .excessiveMotion:
                return .rejected(reason: .movingTooFast)
            case .insufficientFeatures:
                return .rejected(reason: .insufficientFeatures)
            }
        case .notAvailable:
            return .rejected(reason: .movingTooLittle)
        }
    }
    
}
