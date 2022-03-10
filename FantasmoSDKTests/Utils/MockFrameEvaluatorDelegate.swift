//
//  MockFrameEvaluatorDelegate.swift
//  FantasmoSDKTests
//
//  Created by Nicholas Jensen on 01.03.22.
//

import Foundation
@testable import FantasmoSDK

class MockFrameEvaluatorDelegate: FMFrameEvaluatorChainDelegate {
    
    var didStartWindow: ((Date) -> Void)?
    var didRejectFrameWhileEvaluatingOtherFrame: ((FMFrame, FMFrame) -> Void)?
    var didRejectFrameWithFilter: ((FMFrame, FMFrameFilter, FMFrameFilterRejectionReason) -> Void)?
    var didEvaluateNewBestFrame: ((FMFrame) -> Void)?
    var didEvaluateFrameBelowCurrentBestScore: ((FMFrame, Float) -> Void)?
    var didEvaluateFrameBelowMinScoreThreshold: ((FMFrame, Float) -> Void)?
    var didFinishEvaluatingFrame: ((FMFrame) -> Void)?
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didStartWindow startDate: Date) {
        didStartWindow?(startDate)
    }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didRejectFrame frame: FMFrame, whileEvaluatingOtherFrame otherFrame: FMFrame) {
        didRejectFrameWhileEvaluatingOtherFrame?(frame, otherFrame)
    }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didRejectFrame frame: FMFrame, withFilter filter: FMFrameFilter, reason: FMFrameFilterRejectionReason) {
        didRejectFrameWithFilter?(frame, filter, reason)
    }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didEvaluateNewBestFrame newBestFrame: FMFrame) {
        didEvaluateNewBestFrame?(newBestFrame)
    }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didEvaluateFrame frame: FMFrame, belowCurrentBestScore currentBestScore: Float) {
        didEvaluateFrameBelowCurrentBestScore?(frame, currentBestScore)
    }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didEvaluateFrame frame: FMFrame, belowMinScoreThreshold minScoreThreshold: Float) {
        didEvaluateFrameBelowMinScoreThreshold?(frame, minScoreThreshold)
    }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didFinishEvaluatingFrame frame: FMFrame) {
        didFinishEvaluatingFrame?(frame)
    }
}
