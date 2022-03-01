//
//  FMFrameEvaluatorChain.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 21.02.22.
//

import Foundation

protocol FMFrameEvaluatorChainDelegate: AnyObject {
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didEvaluateFrame frame: FMFrame)
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didFindNewBestFrame newBestFrame: FMFrame)
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didDiscardFrame frame: FMFrame)
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didRejectFrame frame: FMFrame, withFilter filter: FMFrameFilter, reason: FMFrameFilterRejectionReason)
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didRejectFrame frame: FMFrame, belowMinScoreThreshold minScoreThreshold: Float)
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didRejectFrame frame: FMFrame, belowCurrentBestScore currentBestScore: Float)
}

class FMFrameEvaluatorChain {
        
    private let minWindowTime: TimeInterval
    private let maxWindowTime: TimeInterval
    private let minScoreThreshold: Float
    private let minHighQualityScore: Float

    private let frameEvaluator: FMFrameEvaluator

    private let frameEvaluationQueue = DispatchQueue(label: "io.fantasmo.frameEvaluationQueue", qos: .userInteractive)
    
    /// Active filters that are run in order before enhancement and evaluation
    let filters: [FMFrameFilter]
    
    /// Image enhancer, applies gamma correction, nil if disabled via remote config
    let imageEnhancer: FMImageEnhancer?
    
    private var currentBestFrame: FMFrame?
    
    private var windowStart: Date
    
    private var isEvaluatingFrame: Bool = false
    
    weak var delegate: FMFrameEvaluatorChainDelegate?
            
    init(config: RemoteConfig.Config) {
        
        // TODO - get these from remote config
        self.minWindowTime = 0.04
        self.maxWindowTime = 1.2
        self.minScoreThreshold = 0.0
        self.minHighQualityScore = 0.9
        
        // configure pre evaluation filters
        
        var enabledFilters: [FMFrameFilter] = []
        
        if config.isTrackingStateFilterEnabled {
            enabledFilters.append(FMTrackingStateFilter())
        }
        
        if config.isCameraPitchFilterEnabled {
            let cameraPitchFilter = FMCameraPitchFilter(
                maxUpwardTiltDegrees: config.cameraPitchFilterMaxUpwardTilt,
                maxDownwardTiltDegrees: config.cameraPitchFilterMaxDownwardTilt
            )
            enabledFilters.append(cameraPitchFilter)
        }
        
        if config.isMovementFilterEnabled {
            let movementFilter = FMMovementFilter(
                threshold: config.movementFilterThreshold
            )
            enabledFilters.append(movementFilter)
        }
                
        self.filters = enabledFilters
        
        // configure the image enhancer, if enabled
        
        if config.isImageEnhancerEnabled {
            imageEnhancer = FMImageEnhancer(targetBrightness: config.imageEnhancerTargetBrightness)
        } else {
            imageEnhancer = nil
        }
        
        // Create our frame evaluator, for now this is just image quality estimation
        frameEvaluator = FMImageQualityEvaluator.makeEvaluator()
        
        windowStart = Date()
    }

    func evaluateAsync(frame: FMFrame) {
        guard Thread.isMainThread else {
            fatalError("evaluateAsync not called on main thread")
        }
                
        // if we're already evaluating a frame, discard it
        guard !isEvaluatingFrame else {
            delegate?.frameEvaluatorChain(self, didDiscardFrame: frame)
            return
        }
                
        // run frame through filters
        var filterResult: FMFrameFilterResult = .accepted
        for filter in filters {
            filterResult = filter.accepts(frame)
            if case let .rejected(reason) = filterResult {
                delegate?.frameEvaluatorChain(self, didRejectFrame: frame, withFilter: filter, reason: reason)
                return
            }
        }
        
        // set a flag so we can only process one frame at a time
        isEvaluatingFrame = true
        
        // begin async stuff
        frameEvaluationQueue.async {
            // TODO - make sure retaining `self` isn't a problem here
            
            // enhance image, apply gamma correction if too dark
            self.imageEnhancer?.enhance(frame: frame)
            
            // evaluate the frame using the configured evaluator
            let evaluation = self.frameEvaluator.evaluate(frame: frame)
            
            DispatchQueue.main.async {
                // process the evaluation on the main thread
                self.processEvaluation(evaluation, frame: frame)
                // unset flag to allow new frames to be evaluated
                self.isEvaluatingFrame = false
            }
        }
    }
    
    private func processEvaluation(_ evaluation: FMFrameEvaluation, frame: FMFrame) {
        guard Thread.isMainThread else {
            fatalError("processEvaluation not called on main thread")
        }
        guard isEvaluatingFrame else {
            fatalError("not evaluating frame")
        }
        
        // store the evaluation on the frame and notify the delegate
        frame.evaluation = evaluation
        delegate?.frameEvaluatorChain(self, didEvaluateFrame: frame)
        
        // check if the frame is above the min score threshold, otherwise return
        if evaluation.score < minScoreThreshold {
            delegate?.frameEvaluatorChain(self, didRejectFrame: frame, belowMinScoreThreshold: minScoreThreshold)
            return
        }
        
        // check if the new frame score is better than our current best frame score, otherwise return
        if let currentBestEvaluation = currentBestFrame?.evaluation, currentBestEvaluation.score > evaluation.score {
            delegate?.frameEvaluatorChain(self, didRejectFrame: frame, belowCurrentBestScore: currentBestEvaluation.score)
            return
        }
        
        // frame is the new best, update our saved reference and notify the delegate
        currentBestFrame = frame
        delegate?.frameEvaluatorChain(self, didFindNewBestFrame: frame)
    }

    func dequeueBestFrame() -> FMFrame? {
        guard let currentBestFrame = currentBestFrame, let evaluation = currentBestFrame.evaluation else {
            return nil
        }
        
        // we have a frame, check if the min window time has passed
        let timeElapsed = Date().timeIntervalSince(windowStart)
        if timeElapsed < minWindowTime {
            return nil
        }
        
        // return the frame if it's high quality or the max window time has passed
        if evaluation.score >= minHighQualityScore || timeElapsed >= maxWindowTime {
            reset()
            return currentBestFrame
        }
        
        return nil
    }

    func reset() {
        windowStart = Date()
        currentBestFrame = nil
    }
    
    func getFilter<T:FMFrameFilter>(ofType type: T.Type) -> T? {
        return filters.first(where: { $0 is T }) as? T
    }
}
