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
    var didRejectFrame: ((FMFrame, FMFrameRejectionReason) -> Void)?
    var didRejectFrameWithFilter: ((FMFrame, FMFrameFilter, FMFrameRejectionReason) -> Void)?
    var didEvaluateNewBestFrame: ((FMFrame) -> Void)?
    var didFinishEvaluatingFrame: ((FMFrame) -> Void)?
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didStartWindow startDate: Date) {
        didStartWindow?(startDate)
    }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didRejectFrame frame: FMFrame, reason: FMFrameRejectionReason) {
        didRejectFrame?(frame, reason)
    }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didRejectFrame frame: FMFrame, withFilter filter: FMFrameFilter, reason: FMFrameRejectionReason) {
        didRejectFrameWithFilter?(frame, filter, reason)
    }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didEvaluateNewBestFrame newBestFrame: FMFrame) {
        didEvaluateNewBestFrame?(newBestFrame)
    }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didFinishEvaluatingFrame frame: FMFrame) {
        didFinishEvaluatingFrame?(frame)
    }
}
