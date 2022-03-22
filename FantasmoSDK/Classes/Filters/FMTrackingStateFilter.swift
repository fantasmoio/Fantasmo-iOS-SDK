//
//  FMTrackingStateFilter.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 23.07.2021.
//

import ARKit

struct FMTrackingStateFilter: FMFrameFilter {
    
    func accepts(_ frame: FMFrame) -> FMFrameFilterResult {
        switch frame.camera.trackingState {
        case .normal:
            return .accepted
        case .limited(let reasonOfLimitedState):
            switch reasonOfLimitedState {
            case .initializing:
                return .rejected(reason: .trackingStateInitializing)
            case .relocalizing:
                return .rejected(reason: .trackingStateRelocalizing)
            case .excessiveMotion:
                return .rejected(reason: .trackingStateExcessiveMotion)
            case .insufficientFeatures:
                return .rejected(reason: .trackingStateInsufficentFeatures)
            default:
                return .accepted
            }
        case .notAvailable:
            return .rejected(reason: .trackingStateNotAvailable)
        }
    }
    
}
