//
//  FMAngleFilter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

class FMAngleFilter: FMFrameFilter {
    let radianThreshold = Float.pi / Float(8)
        
    func accepts(_ frame: ARFrame) -> FMFilterResult {
        switch frame.camera.eulerAngles.x {
        case _ where frame.camera.eulerAngles.x > radianThreshold:
            return .rejected(remedy: .tiltDown)
        case _ where frame.camera.eulerAngles.x < -radianThreshold:
            return .rejected(remedy: .tiltUp)
        default:
            return .accepted
        }
    }
}
