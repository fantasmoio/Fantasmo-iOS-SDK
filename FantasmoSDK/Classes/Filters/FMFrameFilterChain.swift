//
//  FMFrameFilterChain.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

// MARK:-

/// Stateful filter for choosing the frames which are acceptable to localize against.
/// If it is necessary to process a new sequence of frames, then `startOrRestartFiltering()` must be invoked.
class FMFrameFilterChain {
    
    private var lastAcceptTime = clock()
    
    /// The number of seconds after which we forcibly accept a frame.
    private let acceptanceThreshold: Float
    
    /// Filter chain, in order of increasing computational cost
    private let filters: [FMFrameFilter]
    
    init() {
        let rc = RemoteConfig.config()
        acceptanceThreshold = rc.frameAcceptanceThresholdTimeout
        
        var enabledFilters: [FMFrameFilter] = []
        if rc.isTrackingStateFilterEnabled {
            enabledFilters.append(FMTrackingStateFilter())
        }
        
        if rc.isCameraPitchFilterEnabled {
            let cameraPitchFilter = FMCameraPitchFilter(
                maxUpwardTiltDegrees: rc.cameraPitchFilterMaxUpwardTilt,
                maxDownwardTiltDegrees: rc.cameraPitchFilterMaxDownwardTilt
            )
            enabledFilters.append(cameraPitchFilter)
        }
        
        if rc.isMovementFilterEnabled {
            let movementFilter = FMMovementFilter(
                threshold: rc.movementFilterThreshold
            )
            enabledFilters.append(movementFilter)
        }
        
        if rc.isBlurFilterEnabled {
            let blurFilter = FMBlurFilter(
                varianceThreshold: rc.blurFilterVarianceThreshold,
                suddenDropThreshold: rc.blurFilterSuddenDropThreshold,
                averageThroughputThreshold: rc.blurFilterAverageThroughputThreshold
            )
            enabledFilters.append(blurFilter)
        }
        
        if rc.isImageQualityFilterEnabled {
            let imageQualityFilter = FMImageQualityFilter(
                scoreThreshold: rc.imageQualityFilterScoreThreshold
            )
            enabledFilters.append(imageQualityFilter)
        }
        
        
        filters = enabledFilters
    }

    /// Start or restart filtering
    func restart() {
        lastAcceptTime = clock()
    }
    
    /// Accepted frames should be used for the localization.
    func evaluateAsync(_ frame: FMFrame, state: FMLocationManager.State, completion: @escaping ((FMFrameFilterResult) -> Void)) {
        guard Thread.isMainThread else { fatalError("evaluateAsync not called from main thread") }
        
        if shouldForceAccept() {
            lastAcceptTime = clock()
            completion(.accepted)
            return
        }
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            var result: FMFrameFilterResult = .accepted
            let filters: [FMFrameFilter] = self?.filters ?? []
            for filter in filters {
                if case let .rejected(reason) = filter.accepts(frame) {
                    result = .rejected(reason: reason)
                    break
                }
            }
            DispatchQueue.main.async {
                if result == .accepted {
                    self?.lastAcceptTime = clock()
                }
                completion(result)
            }
        }
    }
    
    func getLastImageQualityScore() -> Float {
        guard let imageQualityFilter = filters.first(where: { $0 is FMImageQualityFilter }) as? FMImageQualityFilter else {
            return 0.0
        }
        return imageQualityFilter.lastImageQualityScore
    }
    
    /// If there are a lot of continuous rejections, we force an acceptance
    private func shouldForceAccept() -> Bool {
        let elapsedTime = Float(clock() - lastAcceptTime) / Float(CLOCKS_PER_SEC)
        return (elapsedTime > acceptanceThreshold)
    }
}
