//
//  FMFrameEvaluation.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 21.02.22.
//

import Foundation

enum FMFrameEvaluationType {
    case imageQualityEstimation
}

struct FMFrameEvaluation {
    let type: FMFrameEvaluationType
    let score: Float // 0.0 - 1.0, (1.0 being the best)
    let userInfo: [String: String?]?  // optional analytics etc.
}

enum FMFrameEvaluationResult {
    case newCurrentBest
    case discarded(reason: FMFrameEvaluationDiscardReason)
}

enum FMFrameEvaluationDiscardReason {
    case belowMinScoreThreshold
    case belowCurrentBestScore
    case otherEvaluationInProgress
    case evaluatorError
    case rejectedByFilter(reason: FMFrameFilterRejectionReason)
}
