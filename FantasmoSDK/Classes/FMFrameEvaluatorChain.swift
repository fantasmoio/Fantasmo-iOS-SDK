//
//  FMFrameEvaluatorChain.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 21.02.22.
//

import Foundation

protocol FMFrameEvaluatorChainDelegate: AnyObject {
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didStartWindow startDate: Date)
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didRejectFrame frame: FMFrame, reason: FMFrameRejectionReason)
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didRejectFrame frame: FMFrame, withFilter filter: FMFrameFilter, reason: FMFrameRejectionReason)
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didEvaluateNewBestFrame newBestFrame: FMFrame)
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didFinishEvaluatingFrame frame: FMFrame)
}

class FMFrameEvaluatorChain {
    
    private let frameEvaluator: FMFrameEvaluator

    private let frameEvaluationQueue = DispatchQueue(label: "io.fantasmo.frameEvaluationQueue", qos: .userInteractive)
    
    private(set) var evaluatingFrame: FMFrame?
    
    private(set) var currentBestFrame: FMFrame?
    
    private(set) var windowStart: Date
    
    /// Active filters that are run in order before enhancement and evaluation
    let filters: [FMFrameFilter]
    
    /// Image enhancer, applies gamma correction, nil if disabled via remote config
    let imageEnhancer: FMImageEnhancer?
    
    /// Time in seconds since the last upload before any new uploads can be made. This acts as a rate limiter.
    var minWindowTime: TimeInterval
    
    /// Time in seconds since the last upload after which the `currentBestFrame` (if set) should be uploaded.
    var maxWindowTime: TimeInterval
    
    /// Required minimum evaluation score for a frame to be considered at all. Frames evaluated below this value should be discarded.
    var minScoreThreshold: Float
    
    /// Minimum evaluation score for a frame to be considered "high quality". Any frames evaluated at or above this value will be uploaded
    /// as soon as possible, while still respecting the `minWindowTime`.
    var minHighQualityScore: Float
    
    weak var delegate: FMFrameEvaluatorChainDelegate?
    
    init(config: RemoteConfig.Config) {
        
        // set window and score variables from remote config
        
        minWindowTime = config.minLocalizationWindowTime
        maxWindowTime = config.maxLocalizationWindowTime
        minScoreThreshold = config.minFrameEvaluationScore
        minHighQualityScore = config.minFrameEvaluationHighQualityScore
        
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
                
        // if we're already evaluating a frame, reject it
        if evaluatingFrame != nil {
            delegate?.frameEvaluatorChain(self, didRejectFrame: frame, reason: .otherEvaluationInProgress)
            return
        }
                
        // run frame through filters
        var filterResult: FMFrameFilterResult = .accepted
        for filter in filters {
            filterResult = filter.accepts(frame)
            if case let .rejected(reason) = filterResult {
                // filter rejected the frame
                delegate?.frameEvaluatorChain(self, didRejectFrame: frame, withFilter: filter, reason: reason)
                return
            }
        }
        
        // keep a reference to the frame we're evaluating
        evaluatingFrame = frame
        
        // begin async frame evaluation
        frameEvaluationQueue.async { [weak self] in
            // enhance image, apply gamma correction if too dark
            self?.imageEnhancer?.enhance(frame: frame)
            
            // evaluate the frame using the configured evaluator
            guard let evaluation = self?.frameEvaluator.evaluate(frame: frame) else {
                return // chain deallocated
            }
            
            DispatchQueue.main.async {
                // process the evaluation on the main thread
                self?.processEvaluation(evaluation)
            }
        }
    }
        
    private func processEvaluation(_ evaluation: FMFrameEvaluation) {
        guard Thread.isMainThread else {
            fatalError("processEvaluation not called on main thread")
        }
        guard let frame = evaluatingFrame else {
            fatalError("evaluatingFrame is nil")
        }
        
        // store the evaluation object on the frame
        frame.evaluation = evaluation
        
        if evaluation.score < minScoreThreshold {
            // score is below the min threshold
            delegate?.frameEvaluatorChain(self, didRejectFrame: frame, reason: .scoreBelowMinThreshold)
        }
        else if let currentBestScore = currentBestFrame?.evaluation?.score, currentBestScore > evaluation.score {
            // score is below the current best score
            delegate?.frameEvaluatorChain(self, didRejectFrame: frame, reason: .scoreBelowCurrentBest)
        }
        else {
            // score is the new best, update our current best frame
            currentBestFrame = frame
            delegate?.frameEvaluatorChain(self, didEvaluateNewBestFrame: frame)
        }
        
        // unset the evaluating frame to allow new frames to be evaluated
        self.evaluatingFrame = nil
        
        // notify the delegate that we're finished and can accept new frames
        delegate?.frameEvaluatorChain(self, didFinishEvaluatingFrame: frame)
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
        // check if the max window time has passed, or if the frame is high quality
        if timeElapsed < maxWindowTime && evaluation.score < minHighQualityScore {
            return nil
        }
        // return best frame and start new window
        defer {
            resetWindow()
        }
        return currentBestFrame
    }

    func resetWindow() {
        windowStart = Date()
        currentBestFrame = nil
        delegate?.frameEvaluatorChain(self, didStartWindow: windowStart)
    }
    
    func getFilter<T:FMFrameFilter>(ofType type: T.Type) -> T? {
        return filters.first(where: { $0 is T }) as? T
    }
    
    func getMinWindow() -> Date {
        return windowStart.addingTimeInterval(minWindowTime)
    }
    
    func getMaxWindow() -> Date {
        return windowStart.addingTimeInterval(maxWindowTime)
    }
}
