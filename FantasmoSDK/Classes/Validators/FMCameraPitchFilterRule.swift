//
//  FMAngleFilter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

class FMCameraPitchFilterRule: FMFrameSequenceFilterRule {
    private static let maxPitchDeviationInRad = Float.pi / 8
        
    func check(_ frame: ARFrame) -> Result<Void, FMFrameFilterFailure> {
        // Angle between XZ-plane of world coordinate system and Z-axis of camera.
        let cameraPitchAngleInRad = frame.camera.eulerAngles.x
        
        if abs(cameraPitchAngleInRad) <= FMCameraPitchFilterRule.maxPitchDeviationInRad {
            return .success(())
        } else {
            let failure: FMFrameFilterFailure = (cameraPitchAngleInRad > 0 ? .cameraPitchTooHigh : .cameraPitchTooLow)
            return .failure(failure)
        }
    }
}
