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
        
    func accepts(_ frame: FMFrame) -> FMFrameFilterResult {
        switch frame.fmCamera.pitch {
        case _ where frame.fmCamera.pitch > maxUpwardTilt:
            return .rejected(reason: .pitchTooHigh)
        case _ where frame.fmCamera.pitch < -maxDownwardTilt:
            return .rejected(reason: .pitchTooLow)
        default:
            return .accepted
        }
    }
}
