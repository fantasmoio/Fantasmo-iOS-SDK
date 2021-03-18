//
//  ARFrame+Extension.swift
//  Fantasmo-iOS-SDK-Test-Harness
//
//  Created by lucas kuzma on 3/18/21.
//

import ARKit

extension ARFrame {
    /// Calculate the FMPose difference of self with respect to the given frame
    func poseWithRespectTo(_ frame: ARFrame) -> FMPose {
        return FMPose.diffPose(self.camera.transform, withRespectTo: frame.camera.transform)
    }
}
