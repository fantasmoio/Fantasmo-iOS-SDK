//
//  FMSessionStatisticsView.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 05.10.21.
//

import Foundation
import UIKit
import ARKit

class FMSessionStatisticsView: UIView {

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
    
    @IBOutlet var lastResultLabel: UILabel!
    @IBOutlet var deviceLocationLabel: UILabel!
    
    var lastFrameTimestamp: TimeInterval = 0.0
    
    public func updateThrottled(frame: ARFrame, info: AccumulatedARKitInfo, rejections: FrameFilterRejectionStatisticsAccumulator, refreshRate: TimeInterval = 10.0) {
        let shouldUpdate = frame.timestamp - lastFrameTimestamp > (1.0 / refreshRate)
        guard shouldUpdate else {
            return
        }
        lastFrameTimestamp = frame.timestamp
        let translationVector = frame.camera.transform.columns.3
        let translationFormatted = String(format: "Translation: %.2f, %.2f, %.2f",
                                          translationVector.x, translationVector.y, translationVector.z)
        cameraTranslationLabel.text = translationFormatted
        distanceTraveledLabel.text = String(format: "Distance traveled: %.2fm", info.totalTranslation)
        
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
    
    var localizingStart: Date?
    var uploadingStart: Date?
    
    public func update(state: FMLocationManager.State) {
        let color: UIColor
        switch state {
        case .localizing:
            localizingStart = Date()
            color = .green
        case .uploading:
            uploadingStart = Date()
            color = .orange
        default:
            color = .black
        }
        let text = "Status: \(state.rawValue)"
        managerStatusLabel.attributedText = highlightString(state.rawValue, in: text, color: color)
    }
    
    public func update(lastResult: FMLocationResult?) {
        var lastResultText = "Last result: "
        var uploadingTime: TimeInterval = 0
        var localizingTime: TimeInterval = 0
        if let lastResult = lastResult {
            let coordinate = lastResult.location.coordinate
            lastResultText += String(format: "%f, %f (%@)",
                                     coordinate.latitude, coordinate.longitude,
                                     lastResult.confidence.description)
            if let uploadingStart = uploadingStart {
                uploadingTime = Date().timeIntervalSince(uploadingStart)
                self.uploadingStart = nil
            }
            if let localizingStart = localizingStart {
                localizingTime = Date().timeIntervalSince(localizingStart)
                self.localizingStart = nil
            }
        }
        lastResultText += String(format: "\nLocalize time: %.1fs, Upload time: %.1fs", localizingTime, uploadingTime)
        lastResultLabel.text = lastResultText
    }
    
    public func update(deviceLocation: CLLocation?) {
        var locationText = "Device location: "
        if let coordinate = deviceLocation?.coordinate {
            locationText += String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
        }
        deviceLocationLabel.text = locationText
    }
    
    private func highlightString(_ string: String, in source: String, color: UIColor) -> NSAttributedString {
        let sourceString = source as NSString
        let attributedString = NSMutableAttributedString(string: source)
        let colorRange = sourceString.range(of: string)
        if colorRange.length != NSNotFound {
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color.cgColor, range: colorRange)
        }
        return NSAttributedString(attributedString: attributedString)
    }
}
