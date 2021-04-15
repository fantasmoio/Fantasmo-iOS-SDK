//
//  FMAngleFilter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

class FMCameraPitchValidator: FMFrameValidator {
    private static let maxPitchDeviationInRad = Float.pi / 8
        
    func validate(_ frame: ARFrame) -> Result<Void, FMFrameValidationError> {
        // Angle between XZ-plane of world coordinate system and Z-axis of camera.
        let cameraPitchAngleInRad = frame.camera.eulerAngles.x
        
        if abs(cameraPitchAngleInRad) <= FMCameraPitchValidator.maxPitchDeviationInRad {
            return .success(())
        } else {
            let reason: FMFrameValidationError = (cameraPitchAngleInRad > 0 ? .cameraPitchTooHigh : .cameraPitchTooLow)
            return .failure(reason)
        }
    }
}
