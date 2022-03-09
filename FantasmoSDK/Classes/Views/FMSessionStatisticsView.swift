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

    @IBOutlet var sdkVersionLabel: UILabel!
    @IBOutlet var managerStatusLabel: UILabel!
    
    @IBOutlet var translationLabel: UILabel!
    @IBOutlet var totalTranslationLabel: UILabel!
    @IBOutlet var remoteConfigLabel: UILabel!
    
    @IBOutlet var framesEvaluatedLabel: UILabel!
    @IBOutlet var lastFrameScoreLabel: UILabel!

    @IBOutlet var framesRejectedLabel: UILabel!
    @IBOutlet var lastFrameRejectionLabel: UILabel!
    
    @IBOutlet var eulerAnglesLabel: UILabel!
    @IBOutlet var eulerAngleSpreadsLabel: UILabel!
    
    @IBOutlet var lastResultLabel: UILabel!
    @IBOutlet var errorsLabel: UILabel!
    @IBOutlet var deviceLocationLabel: UILabel!
    
    var lastFrameTimestamp: TimeInterval = 0.0
        
    override func awakeFromNib() {
        super.awakeFromNib()
        sdkVersionLabel.text = "Fantasmo SDK \(FMSDKInfo.fullVersion)"
        remoteConfigLabel.text = "Remote Config: \(RemoteConfig.config().remoteConfigId)"
    }
        
    public func updateThrottled(frame: FMFrame, info: AccumulatedARKitInfo, refreshRate: TimeInterval = 10.0) {
        let shouldUpdate = frame.timestamp - lastFrameTimestamp > (1.0 / refreshRate)
        guard shouldUpdate else {
            return
        }
        lastFrameTimestamp = frame.timestamp
        
        let translationVector = frame.camera.transform.columns.3
        let translationFormatted = String(format: "Translation: %.2f, %.2f, %.2f",
                                          translationVector.x, translationVector.y, translationVector.z)
        translationLabel.text = translationFormatted
        totalTranslationLabel.text = String(format: "Total translation: %.2fm", info.totalTranslation)
        
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
    }
    
    public func update(frameEvaluations: FMFrameEvaluationStatistics) {
        framesEvaluatedLabel.text = "Frames evaluated: \(frameEvaluations.count)"
        if let lastScore = frameEvaluations.lastScore {
            lastFrameScoreLabel.text = String(format: "Last score: %.5f", lastScore)
        }
        lastFrameRejectionLabel.text = ""
    }

    public func update(frameRejections: FMFrameRejectionStatistics) {
        framesRejectedLabel.text = "Frames rejected: \(frameRejections.filterRejectionsCount)"
        if let lastRejection = frameRejections.lastFilterRejection {
            lastFrameRejectionLabel.text = lastRejection.rawValue
        }
    }
    
    /*
        var imageEnhancementText = "Gamma correction: "
        if let gamma = frame.enhancedImageGamma {
             imageEnhancementText += "\(gamma)"
        } else {
             imageEnhancementText += "none"
        }
        imageEnhancementLabel.text = imageEnhancementText
             
        let frameStats = info.trackingStateStatistics
        frameStatsNormalLabel.text = "Normal: \(frameStats.framesWithNormalTrackingState)"
        frameStatsLimitedLabel.text = "Limited: \(frameStats.framesWithLimitedTrackingState)"
        frameStatsNotAvailableLabel.text = "Not available: \(frameStats.framesWithNotAvailableTracking)"
        frameStatsExcessiveMotionLabel.text = "Excessive motion: \(frameStats.framesWithLimitedTrackingStateByReason[.excessiveMotion]!)"
        frameStatsInsufficientFeaturesLabel.text = "Insufficient features: \(frameStats.framesWithLimitedTrackingStateByReason[.insufficientFeatures]!)"

        let rejectionCounts = rejections.counts
        filterStatsPitchLowLabel.text = "Pitch low: \(rejectionCounts[.pitchTooLow] ?? 0)"
        filterStatsPitchHighLabel.text = "Pitch high: \(rejectionCounts[.pitchTooHigh] ?? 0)"
        filterStatsTooFastLabel.text = "Too fast: \(rejectionCounts[.movingTooFast] ?? 0)"
        filterStatsTooLittleLabel.text = "Too little: \(rejectionCounts[.movingTooLittle] ?? 0)"
        filterStatsFeaturesLabel.text = "Features: \(rejectionCounts[.insufficientFeatures] ?? 0)"
     */
    
    public func update(activeUploads: [FMFrame]) {
        
    }
        
    public func update(state: FMLocationManager.State) {
        let color: UIColor
        switch state {
        case .localizing:
            color = .green
        case .stopped:
            color = .orange
        }
        let text = "Status: \(state.rawValue)"
        managerStatusLabel.attributedText = highlightString(state.rawValue, in: text, color: color)
    }
    
    public func update(errorCount: Int, lastError: FMError?) {
        var errorText = "Errors: \(errorCount)"
        if let lastErrorDescription = lastError?.debugDescription {
            errorText += "\nLast error: \(lastErrorDescription)"
            errorsLabel.attributedText = highlightString(lastErrorDescription, in: errorText, color: .red)
        } else {
            errorsLabel.text = errorText
        }
    }
    
    public func update(lastResult: FMLocationResult?) {
        var lastResultText = "Last result: "
        if let lastResult = lastResult {
            let coordinate = lastResult.location.coordinate
            lastResultText += String(format: "%f, %f (%@)",
                                     coordinate.latitude, coordinate.longitude,
                                     lastResult.confidence.description)
        }
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
