//
//  ARKitInfo.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 14.07.2021.
//

import ARKit

/// Accumulator of statistics on frames and some additional integrated data like total translation (trajectory length) and rotation spread of camera.
public class FrameBasedInfoAccumulator {
    
    /// Accumulator of statistics on the rejections of frame filter.
    private(set) var filterRejectionStatisticsAccumulator = FrameFilterRejectionStatisticsAccumulator()
    
    public private(set) var trackingStateStatisticsAccumulator = TrackingStateStatisticsAccumulator()

    
    /// Current value of total translation in meters
    public var totalTranslation: Float {
        translationAccumulator.totalTranslation
    }

    /// Allows to receive the total translation (distance) that device has moded from the starting moment.
    private(set) var translationAccumulator = TotalDeviceTranslationAccumulator(decimationFactor: 10)
    
    /// Spread of Eugler angles as min and max values for each compoent (that is for yaw, pitch and roll)
    public private(set) var eulerAngleSpreadsAccumulator = EulerAngleSpreadsAccumulator()
    
    public init() {}
    
    /// - Parameter frameQualityFilterResult: the result of filtering the passed `nextFrame` through the frame quality filter. Can be `nil`
    ///         in case when the frame was not passed through the filter (what happens when the "localize image" request is in progress)
    func accumulate(nextFrame: ARFrame, frameQualityFilterResult: FMFrameFilterResult?) {
        if case let .rejected(reason) = frameQualityFilterResult {
            filterRejectionStatisticsAccumulator.accumulate(filterRejectionReason: reason)
        }
        
        trackingStateStatisticsAccumulator.accumulate(nextTrackingState: nextFrame.camera.trackingState)
        translationAccumulator.update(with: nextFrame)
        
        if case .normal = nextFrame.camera.trackingState {
            let eulerAngles = EulerAngles(nextFrame.camera.eulerAngles)
            eulerAngleSpreadsAccumulator.accumulate(nextEulerAngles: eulerAngles, trackingState: nextFrame.camera.trackingState)
        }
    }
    
    func reset() {
        filterRejectionStatisticsAccumulator.reset()
        trackingStateStatisticsAccumulator.reset()
        translationAccumulator.reset()
        eulerAngleSpreadsAccumulator = EulerAngleSpreadsAccumulator()
    }
}
