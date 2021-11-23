//
//  FMImageQualityFilter.swift.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 18.11.21.
//

import ARKit

class FMImageQualityFilter: FMFrameFilter {

    private var imageQualityEstimator = ImageQualityEstimator.makeEstimator()
    
    private let scoreThreshold: Float
    
    public private(set) var lastImageQualityScore: Float = 0.0
    
    init(scoreThreshold: Float) {
        self.scoreThreshold = scoreThreshold
    }
    
    public func accepts(_ frame: FMFrame) -> FMFrameFilterResult {
        let iqeResult = imageQualityEstimator.estimateImageQuality(from: frame.capturedImage)
        switch iqeResult {
        case .error(let message):
            log.error("iqe - error: \(message)")
            return .accepted
        case .unknown:
            log.info("iqe - no prediction")
            return .accepted
        case .estimate(let score):
            log.info("iqe - score: \(score)")
            lastImageQualityScore = score
            return score >= scoreThreshold ? .accepted : .rejected(reason: .imageQualityScoreBelowThreshold)
        }
    }
}

