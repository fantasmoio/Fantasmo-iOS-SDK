//
//  FMImageQualityFilter.swift.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 18.11.21.
//

import ARKit

class FMImageQualityFilter: FMFrameFilter {

    private var imageQualityEstimator = ImageQualityEstimator.makeEstimator()
    
    public private(set) var lastImageQualityScore: Float = 0.0
    
    public func accepts(_ frame: FMFrame) -> FMFrameFilterResult {
        let startDate = Date()
        let iqe = imageQualityEstimator.estimateImageQuality(from: frame.capturedImage)
        switch iqe {
        case .error(let message):
            log.error("iqe error: \(message)")
        case .unknown:
            log.info("iqe unknown")
        case .estimate(let score):
            log.info("iqe score: \(score)")
            log.info("iqe time: \(Date().timeIntervalSince(startDate)) seconds")
            lastImageQualityScore = score
        }
        return .accepted
    }
}

