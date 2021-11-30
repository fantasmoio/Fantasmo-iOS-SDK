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
    
    /// Active frame filters, in order of increasing computational cost
    let filters: [FMFrameFilter]
    
    init(config: RemoteConfig.Config) {

        acceptanceThreshold = config.frameAcceptanceThresholdTimeout
                
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
        
        if config.isBlurFilterEnabled {
            let blurFilter = FMBlurFilter(
                varianceThreshold: config.blurFilterVarianceThreshold,
                suddenDropThreshold: config.blurFilterSuddenDropThreshold,
                averageThroughputThreshold: config.blurFilterAverageThroughputThreshold
            )
            enabledFilters.append(blurFilter)
        }
        
        if config.isImageQualityFilterEnabled, #available(iOS 13, *) {
            let imageQualityFilter = FMImageQualityFilter(
                scoreThreshold: config.imageQualityFilterScoreThreshold
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
    
    func getFilter<T:FMFrameFilter>(ofType type: T.Type) -> T? {
        return filters.first(where: { $0 is T }) as? T
    }
    
    /// If there are a lot of continuous rejections, we force an acceptance
    private func shouldForceAccept() -> Bool {
        let elapsedTime = Float(clock() - lastAcceptTime) / Float(CLOCKS_PER_SEC)
        return (elapsedTime > acceptanceThreshold)
    }
}
