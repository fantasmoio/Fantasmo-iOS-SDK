//
//  FMAngleFilter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

class FMCameraPitchFilter: FMFrameFilter {
    let maxUpwardTiltRadians: Float
    let maxDownwardTiltRadians: Float
    
    init(maxUpwardTiltDegrees: Float, maxDownwardTiltDegrees: Float) {
        self.maxUpwardTiltRadians = deg2rad(maxUpwardTiltDegrees)
        self.maxDownwardTiltRadians = deg2rad(maxDownwardTiltDegrees)
    }
    
    func accepts(_ frame: FMFrame) -> FMFrameFilterResult {
        switch frame.fmCamera.pitch {
        case _ where frame.fmCamera.pitch > maxUpwardTiltRadians:
            return .rejected(reason: .pitchTooHigh)
        case _ where frame.fmCamera.pitch < -maxDownwardTiltRadians:
            return .rejected(reason: .pitchTooLow)
        default:
            return .accepted
        }
    }
}
