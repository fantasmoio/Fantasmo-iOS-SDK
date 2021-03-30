//
//  FMAngleFilter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

class FMAngleFilter: FMFrameFilter {
    let radianThreshold = Float.pi / Float(8)
    
    func accepts(_ frame: ARFrame) -> Bool {
        return abs(frame.camera.eulerAngles.x) < radianThreshold
    }
}
