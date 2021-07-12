//
//  FMAngleFilter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

class FMCameraPitchFilter: FMFrameFilter {
    let radianThreshold = Float.pi / 8
        
    func accepts(_ frame: ARFrame) -> FMFrameFilterResult {
        switch frame.camera.eulerAngles.x {
        case _ where frame.camera.eulerAngles.x > radianThreshold:
            return .rejected(reason: .cameraPitchTooHigh)
        case _ where frame.camera.eulerAngles.x < -radianThreshold:
            return .rejected(reason: .cameraPitchTooLow)
        default:
            return .accepted
        }
    }
}
