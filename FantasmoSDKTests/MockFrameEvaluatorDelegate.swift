//
//  MockFrameEvaluatorDelegate.swift
//  FantasmoSDKTests
//
//  Created by Nicholas Jensen on 01.03.22.
//

import Foundation
@testable import FantasmoSDK

class MockFrameEvaluatorDelegate: FMFrameEvaluatorChainDelegate {
    
    var didEvaluateFrame: ((FMFrame) -> Void) = { _ in }
    var didFindNewBestFrame: ((FMFrame) -> Void) = { _ in }
    var didDiscardFrame: ((FMFrame) -> Void) = { _ in }
    var didRejectFrameWithFilter: ((FMFrame, FMFrameFilter, FMFrameFilterRejectionReason) -> Void) = { _, _, _ in }
    var didRejectFrameBelowMinScoreThreshold: ((FMFrame, Float) -> Void) = { _, _ in }
    var didRejectFrameBelowCurrentBestScore: ((FMFrame, Float) -> Void) = { _, _ in }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didEvaluateFrame frame: FMFrame) {
        didEvaluateFrame(frame)
    }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didFindNewBestFrame newBestFrame: FMFrame) {
        didFindNewBestFrame(newBestFrame)
    }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didDiscardFrame frame: FMFrame) {
        didDiscardFrame(frame)
    }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didRejectFrame frame: FMFrame, withFilter filter: FMFrameFilter, reason: FMFrameFilterRejectionReason) {
        didRejectFrameWithFilter(frame, filter, reason)
    }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didRejectFrame frame: FMFrame, belowMinScoreThreshold minScoreThreshold: Float) {
        didRejectFrameBelowMinScoreThreshold(frame, minScoreThreshold)
    }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didRejectFrame frame: FMFrame, belowCurrentBestScore currentBestScore: Float) {
        didRejectFrameBelowCurrentBestScore(frame, currentBestScore)
    }
}
