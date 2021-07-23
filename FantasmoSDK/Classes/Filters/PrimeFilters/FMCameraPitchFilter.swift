//
//  FMAngleFilter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

class FMCameraPitchFilter: FMFrameFilter {
    private let maxUpwardTilt: Float = deg2rad(30)
    private let maxDownwardTilt: Float = deg2rad(65)
        
    func accepts(_ frame: ARFrame) -> FMFrameFilterResult {
        switch frame.camera.pitch {
        case _ where frame.camera.pitch > maxUpwardTilt:
            return .rejected(reason: .cameraPitchTooHigh)
        case _ where frame.camera.pitch < -maxDownwardTilt:
            return .rejected(reason: .cameraPitchTooLow)
        default:
            return .accepted
        }
    }
}
