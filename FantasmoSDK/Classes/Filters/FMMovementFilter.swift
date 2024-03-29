//
//  FMMovementFilter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

class FMMovementFilter: FMFrameFilter {
    let threshold: Float
    var lastTransform: simd_float4x4 = simd_float4x4(1)

    init(threshold: Float) {
        self.threshold = threshold
    }
    
    public func accepts(_ frame: FMFrame) -> FMFrameFilterResult {
        if exceededThreshold(frame.camera.transform) {
            lastTransform = frame.camera.transform
            return .accepted
        } else {
            return .rejected(reason: .movingTooLittle)
        }
    }
    
    private func exceededThreshold(_ newTransform:simd_float4x4) -> Bool {
        return !simd_almost_equal_elements(lastTransform, newTransform, threshold)
    }
}

