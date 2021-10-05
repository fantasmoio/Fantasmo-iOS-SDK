//
//  FMSessionStatisticsView.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 05.10.21.
//

import Foundation
import UIKit
import ARKit

internal class FMSessionStatisticsView: UIView {

    @IBOutlet var managerStatusLabel: UILabel!
    @IBOutlet var cameraTranslationLabel: UILabel!
    @IBOutlet var distanceTraveledLabel : UILabel!
    @IBOutlet var eulerAnglesLabel: UILabel!
    @IBOutlet var eulerAngleSpreadsLabel: UILabel!
    @IBOutlet var frameStatsNormalLabel: UILabel!
    @IBOutlet var frameStatsLimitedLabel: UILabel!
    @IBOutlet var frameStatsNotAvailableLabel: UILabel!
    @IBOutlet var frameStatsExcessiveMotionLabel: UILabel!
    @IBOutlet var frameStatsInsufficientFeaturesLabel: UILabel!
    @IBOutlet var filterStatsPitchLowLabel: UILabel!
    @IBOutlet var filterStatsPitchHighLabel: UILabel!
    @IBOutlet var filterStatsBlurryLabel: UILabel!
    @IBOutlet var filterStatsTooFastLabel: UILabel!
    @IBOutlet var filterStatsTooLittleLabel: UILabel!
    @IBOutlet var filterStatsFeaturesLabel: UILabel!
    
    var lastUpdateTimestamp: TimeInterval = 0.0
    
    public func updateThrottled(frame: ARFrame, info: AccumulatedARKitInfo, rejections: FrameFilterRejectionStatisticsAccumulator, refreshRate: TimeInterval = 10.0) {
        let shouldUpdate = frame.timestamp - lastUpdateTimestamp > (1.0 / refreshRate)
        guard shouldUpdate else {
            return
        }
        lastUpdateTimestamp = frame.timestamp
        let translationVector = frame.camera.transform.columns.3
        let translationFormatted = String(format: "Camera Translation: %.2f, %.2f, %.2f",
                                          translationVector.x, translationVector.y, translationVector.z)
        cameraTranslationLabel.text = translationFormatted
        distanceTraveledLabel.text = String(format: "Distance Traveled: %.2fm", info.totalTranslation)
        
        let eulerAngles = EulerAngles(frame.camera.eulerAngles)
        eulerAnglesLabel.text = eulerAngles.description(format: "Euler Angles: %.2f˚, %.2f˚, %.2f˚", units: .degrees)
        
        let eulerAngleSpreads = info.eulerAngleSpreadsAccumulator
        let eulerAngleSpreadsText = String(
            format: "Euler Angle Spreads:\n\t(%.2f˚, %.2f˚) %.2f˚\n\t(%.2f˚, %.2f˚) %.2f˚\n\t(%.2f˚, %.2f˚) %.2f˚",
            rad2deg(eulerAngleSpreads.pitch.minRotationAngle), rad2deg(eulerAngleSpreads.pitch.maxRotationAngle), rad2deg(eulerAngleSpreads.pitch.spread),
            rad2deg(eulerAngleSpreads.yaw.minRotationAngle), rad2deg(eulerAngleSpreads.yaw.maxRotationAngle), rad2deg(eulerAngleSpreads.yaw.spread),
            rad2deg(eulerAngleSpreads.roll.minRotationAngle), rad2deg(eulerAngleSpreads.roll.maxRotationAngle), rad2deg(eulerAngleSpreads.roll.spread)
        )
        eulerAngleSpreadsLabel.text = eulerAngleSpreadsText
        
        let frameStats = info.trackingStateStatistics
        frameStatsNormalLabel.text = "Normal: \(frameStats.framesWithNormalTrackingState)"
        frameStatsLimitedLabel.text = "Limited: \(frameStats.framesWithLimitedTrackingState)"
        frameStatsNotAvailableLabel.text = "Not available: \(frameStats.framesWithNotAvailableTracking)"
        frameStatsExcessiveMotionLabel.text = "Excessive motion: \(frameStats.framesWithLimitedTrackingStateByReason[.excessiveMotion]!)"
        frameStatsInsufficientFeaturesLabel.text = "Insufficient features: \(frameStats.framesWithLimitedTrackingStateByReason[.insufficientFeatures]!)"
        
        let rejectionCounts = rejections.counts
        filterStatsPitchLowLabel.text = "Pitch low: \(rejectionCounts[.pitchTooLow] ?? 0)"
        filterStatsPitchHighLabel.text = "Pitch high: \(rejectionCounts[.pitchTooHigh] ?? 0)"
        filterStatsBlurryLabel.text = "Blurry: \(rejectionCounts[.imageTooBlurry] ?? 0)"
        filterStatsTooFastLabel.text = "Too fast: \(rejectionCounts[.movingTooFast] ?? 0)"
        filterStatsTooLittleLabel.text = "Too little: \(rejectionCounts[.movingTooLittle] ?? 0)"
        filterStatsFeaturesLabel.text = "Features: \(rejectionCounts[.insufficientFeatures] ?? 0)"
    }
    
    var stateTimer: Timer?
    var stateTimerStart: Date?
    
    public func updateTimed(state: FMLocationManager.State) {
        update(state: state)
        stateTimerStart = Date()
        stateTimer?.invalidate()
        stateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let stateTimerStart = self?.stateTimerStart else { return }
            let seconds = Date().timeIntervalSince(stateTimerStart)
            self?.update(state: state, timeElapsed: seconds)
        }
    }
    
    public func update(state: FMLocationManager.State, timeElapsed: TimeInterval = 0) {
        let text = "Status: \(state.rawValue), Time: \(String(format:"%.1f", timeElapsed))s" as NSString
        let attributedText = NSMutableAttributedString(string: text as String)
        let statusRange = text.range(of: state.rawValue)
        if statusRange.length != NSNotFound {
            let color: UIColor
            switch state {
            case .uploading:
                color = .orange
            case .localizing:
                color = .green
            default:
                color = .darkGray
            }
            attributedText.addAttribute(NSAttributedString.Key.foregroundColor, value: color.cgColor, range: statusRange)
        }
        managerStatusLabel.attributedText = attributedText
    }
    
    deinit {
        stateTimer?.invalidate()
    }
}
