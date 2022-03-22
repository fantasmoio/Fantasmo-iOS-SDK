//
//  FMFrameRejectionReason.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 21.03.22.
//

import Foundation

enum FMFrameRejectionReason: String, CaseIterable {
    case pitchTooLow
    case pitchTooHigh
    case movingTooFast
    case movingTooLittle
    case trackingStateInitializing
    case trackingStateRelocalizing
    case trackingStateExcessiveMotion
    case trackingStateInsufficentFeatures
    case trackingStateNotAvailable
    case otherEvaluationInProgress
    case scoreBelowCurrentBest
    case scoreBelowMinThreshold
}
