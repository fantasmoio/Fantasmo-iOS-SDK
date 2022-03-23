//
//  FMFrameRejectionReason.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 21.03.22.
//

import Foundation

enum FMFrameRejectionReason: String, CaseIterable {
    // filter rejections
    case pitchTooLow
    case pitchTooHigh
    case movingTooFast
    case movingTooLittle
    case trackingStateInitializing
    case trackingStateRelocalizing
    case trackingStateExcessiveMotion
    case trackingStateInsufficentFeatures
    case trackingStateNotAvailable
    // evaluator rejections
    case otherEvaluationInProgress
    case scoreBelowCurrentBest
    case scoreBelowMinThreshold
}
