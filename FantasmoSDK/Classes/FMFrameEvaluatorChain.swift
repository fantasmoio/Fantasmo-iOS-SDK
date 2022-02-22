//
//  FMFrameEvaluatorChain.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 21.02.22.
//

import Foundation

protocol FMFrameEvaluatorChainDelegate: AnyObject {
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didEvaluateFrame frame: FMFrame, result: FMFrameEvaluationResult)
}

class FMFrameEvaluatorChain: FMFrameEvaluator {
        
    private let minWindowTime: TimeInterval
    private let maxWindowTime: TimeInterval
    private let minScoreThreshold: Float
    private let minHighQualityScore: Float

    private let frameEvaluator: FMFrameEvaluator?

    private let frameEvaluationQueue = DispatchQueue(label: "io.fantasmo.frameEvaluationQueue", qos: .userInteractive)
    
    /// Active filters that are run in order before enhancement and evaluation
    let preEvaluationFilters: [FMFrameFilter]
    
    /// Image enhancer, applies gamma correction, nil if disabled via remote config
    let imageEnhancer: FMImageEnhancer?
    
    private var currentBestFrame: FMFrame?
    
    private var windowStart: Date?
    
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
                
        self.preEvaluationFilters = enabledFilters
        
        // configure the image enhancer, if enabled
        
        if config.isImageEnhancerEnabled {
            imageEnhancer = FMImageEnhancer(targetBrightness: config.imageEnhancerTargetBrightness)
        } else {
            imageEnhancer = nil
        }
        
        if #available(iOS 13.0, *) {
            // TODO - someday, use factory to create any configured evaluator
            frameEvaluator = FMImageQualityEvaluator()
        } else {
            frameEvaluator = nil
        }
    }

    func evaluate(frame: FMFrame) {
        guard Thread.isMainThread else {
            fatalError("evaluate not called on main thread")
        }
        
        // if already evaluating a frame, return
        guard !isEvaluatingFrame else {
            delegate?.frameEvaluatorChain(self, didEvaluateFrame: frame, result: .discarded(reason: .otherEvaluationInProgress))
            return
        }
        
        if windowStart == nil {
            windowStart = Date()
        }
        
        // run frame through filters
        var filterResult: FMFrameFilterResult = .accepted
        for filter in preEvaluationFilters {
            filterResult = filter.accepts(frame)
            if filterResult != .accepted {
                break
            }
        }
        
        // if any filter rejects, throw frame away
        if case let .rejected(reason) = filterResult {
            delegate?.frameEvaluatorChain(self, didEvaluateFrame: frame, result: .discarded(reason: .rejectedByFilter(reason: reason)))
            return
        }
        
        // set a flag so we can only process one frame at a time
        isEvaluatingFrame = true
        
        // begin async stuff
        frameEvaluationQueue.async { [weak self] in
            
            // enhance image, apply gamma correction if too dark
            self?.imageEnhancer?.enhance(frame: frame)
            
            // evaluate the frame using the configured evaluator
            self?.frameEvaluator?.evaluate(frame: frame)
            
            DispatchQueue.main.async {
                // finish evaluation on the main thread
                self?.finishEvaluation(frame: frame)
                // unset flag to allow new frames to be evaluated
                self?.isEvaluatingFrame = false
            }
        }
    }
    
    private func finishEvaluation(frame: FMFrame) {
        guard Thread.isMainThread else {
            fatalError("finishEvaluation not called on main thread")
        }
        
        guard isEvaluatingFrame else {
            fatalError("not evaluating frame")
        }
        
        guard let evaluation = frame.evaluation else {
            // evaluation either failed, is disabled, or the version of iOS is unsupported
            if currentBestFrame?.evaluation == nil {
                // there is no current best frame, or it has no evaluation
                currentBestFrame = frame
                delegate?.frameEvaluatorChain(self, didEvaluateFrame: frame, result: .newCurrentBest)
            } else {
                delegate?.frameEvaluatorChain(self, didEvaluateFrame: frame, result: .discarded(reason: .evaluatorError))
            }
            return
        }
        
        // check if the frame is above the min score threshold, otherwise throw it away
        if evaluation.score < minScoreThreshold {
            delegate?.frameEvaluatorChain(self, didEvaluateFrame: frame, result: .discarded(reason: .belowMinScoreThreshold))
            return
        }

        // check if the new frame is better than our current best, otherwise throw it away
        if let currentBestEvaluation = currentBestFrame?.evaluation, currentBestEvaluation.score > evaluation.score {
            delegate?.frameEvaluatorChain(self, didEvaluateFrame: frame, result: .discarded(reason: .belowCurrentBestScore))
            return
        }
        
        // update our current best frame
        currentBestFrame = frame
        delegate?.frameEvaluatorChain(self, didEvaluateFrame: frame, result: .newCurrentBest)
    }

    func dequeueBestFrame() -> FMFrame? {
        guard let windowStart = windowStart,
              let currentBestFrame = currentBestFrame,
              let evaluation = currentBestFrame.evaluation
        else {
            return nil
        }
        
        let timeElapsed = Date().timeIntervalSince(windowStart)
        guard timeElapsed >= minWindowTime else {
            return nil
        }
        
        if evaluation.score >= minHighQualityScore || timeElapsed >= maxWindowTime {
            self.currentBestFrame = nil
            self.windowStart = Date()
            return currentBestFrame
        }
                
        return nil
    }

    func reset() {
        // TODO - reset window state, close current window etc.
        windowStart = nil
        currentBestFrame = nil
    }
    
    func getFilter<T:FMFrameFilter>(ofType type: T.Type) -> T? {
        return preEvaluationFilters.first(where: { $0 is T }) as? T
    }
}
