//
//  FMImageQualityFilter.swift.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 18.11.21.
//

import ARKit

class FMImageQualityFilter: FMFrameFilter {

    var imageQualityEstimator = ImageQualityEstimator.makeEstimator()
    
    public func accepts(_ frame: FMFrame) -> FMFrameFilterResult {
        let startDate = Date()
        let iqe = imageQualityEstimator.estimateImageQuality(from: frame.capturedImage)
        switch iqe {
        case .error(let message):
            log.error("iqe error: \(message)")
            return .accepted
        case .unknown:
            log.info("iqe unknown")
            return .accepted
        case .estimate(let score):
            log.info("iqe score: \(score)")
            log.info("iqe time: \(Date().timeIntervalSince(startDate)) seconds")
            return .accepted
        }
    }
}

