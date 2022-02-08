//
//  FMFrameFilterChain.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

/// A chain of active `FMFrameFilter` instances through which ARFrames can be run.
/// Frames are evaluated asynchronously and in order by each filter in the chain until
/// either one of filters rejects the frame, or all of the filters accept it.
class FMFrameFilterChain {
    
    private var lastAcceptTime = clock()
    
    /// The number of seconds after which we forcibly accept a frame, bypassing the filters
    private let acceptanceThreshold: Float
    
    /// Active filters that are run in order before image enhancement
    let preImageEnhancementFilters: [FMFrameFilter]
    
    /// Active filters that are run in order after image enhancement
    let postImageEnhancementFilters: [FMFrameFilter]
    
    /// All active filters, pre + post image enhancement
    var allFilters: [FMFrameFilter] { return preImageEnhancementFilters + postImageEnhancementFilters }
    
    /// Frame image enhancer, nil if disabled via remote config
    let imageEnhancer: FMImageEnhancer?
    
        
    init(config: RemoteConfig.Config) {

        acceptanceThreshold = config.frameAcceptanceThresholdTimeout
            
        // configure pre image enhancement filters
        var enabledPreImageEnhancementFilters: [FMFrameFilter] = []
        if config.isTrackingStateFilterEnabled {
            enabledPreImageEnhancementFilters.append(FMTrackingStateFilter())
        }
        
        if config.isCameraPitchFilterEnabled {
            let cameraPitchFilter = FMCameraPitchFilter(
                maxUpwardTiltDegrees: config.cameraPitchFilterMaxUpwardTilt,
                maxDownwardTiltDegrees: config.cameraPitchFilterMaxDownwardTilt
            )
            enabledPreImageEnhancementFilters.append(cameraPitchFilter)
        }
        
        if config.isMovementFilterEnabled {
            let movementFilter = FMMovementFilter(
                threshold: config.movementFilterThreshold
            )
            enabledPreImageEnhancementFilters.append(movementFilter)
        }
        
        self.preImageEnhancementFilters = enabledPreImageEnhancementFilters
        
        var enabledPostImageEnhancementFilters: [FMFrameFilter] = []
        if config.isBlurFilterEnabled {
            let blurFilter = FMBlurFilter(
                varianceThreshold: config.blurFilterVarianceThreshold,
                suddenDropThreshold: config.blurFilterSuddenDropThreshold,
                averageThroughputThreshold: config.blurFilterAverageThroughputThreshold
            )
            enabledPostImageEnhancementFilters.append(blurFilter)
        }
        
        if config.isImageQualityFilterEnabled, #available(iOS 13, *) {
            let imageQualityFilter = FMImageQualityFilter(
                scoreThreshold: config.imageQualityFilterScoreThreshold
            )
            enabledPostImageEnhancementFilters.append(imageQualityFilter)
        }
        
        self.postImageEnhancementFilters = enabledPostImageEnhancementFilters
        
        if config.isImageEnhancerEnabled {
            imageEnhancer = FMImageEnhancer(targetBrightness: config.imageEnhancerTargetBrightness)
        } else {
            imageEnhancer = nil
        }
    }

    /// Start or restart filtering
    func restart() {
        lastAcceptTime = clock()
    }
    
    /// Accepted frames should be used for the localization.
    func evaluate(_ frame: FMFrame) -> FMFrameFilterResult {
        guard !Thread.isMainThread else { fatalError("evaluate called from main thread") }
        
        if shouldForceAccept() {
            // enhance the image before force accepting
            imageEnhancer?.enhance(frame: frame)
            lastAcceptTime = clock()
            return .accepted
        }
                
        // evaluate pre image enhancement filters
        var result: FMFrameFilterResult = .accepted
        for filter in self.preImageEnhancementFilters {
            if case let .rejected(reason) = filter.accepts(frame) {
                // return if any rejected the frame
                return .rejected(reason: reason)
            }
        }
        
        // enhance the image applying gamma correction
        // this makes the `enhancedImage` and `enhancedImageGamma`
        // frame properties available to the next filters
        imageEnhancer?.enhance(frame: frame)
        
        // evaluate post image enhancement filters
        for filter in self.postImageEnhancementFilters {
            if case let .rejected(reason) = filter.accepts(frame) {
                result = .rejected(reason: reason)
                break
            }
        }
        
        if result == .accepted {
            lastAcceptTime = clock()
        }
        return result
    }
    
    func getFilter<T:FMFrameFilter>(ofType type: T.Type) -> T? {
        return allFilters.first(where: { $0 is T }) as? T
    }
    
    /// If there are a lot of continuous rejections, we force an acceptance
    private func shouldForceAccept() -> Bool {
        let elapsedTime = Float(clock() - lastAcceptTime) / Float(CLOCKS_PER_SEC)
        return (elapsedTime > acceptanceThreshold)
    }
}
