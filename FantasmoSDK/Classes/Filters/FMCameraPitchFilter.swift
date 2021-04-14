//
//  FMAngleFilter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

class FMCameraPitchFilter: FMFrameFilter {
    private static let maxPitchDeviationInRad = Float.pi / 8
        
    func accepts(_ frame: ARFrame) -> FMFilterResult {
        // Angle between XZ-plane of world coordinate system and Z-axis of camera.
        let cameraPitchAngleInRad = frame.camera.eulerAngles.x
        
        if abs(cameraPitchAngleInRad) <= FMCameraPitchFilter.maxPitchDeviationInRad {
            return .accepted
        } else {
            let reason: FMFilterRejectionReason = (cameraPitchAngleInRad > 0 ? .pitchTooHigh : .pitchTooLow)
            return .rejected(reason: reason)
        }
    }
}
