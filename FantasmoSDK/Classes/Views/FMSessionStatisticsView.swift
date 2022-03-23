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

    @IBOutlet var uploadStackView: UIStackView!
    
    @IBOutlet var totalRejectionsLabel: UILabel!
    @IBOutlet var rejectionStackView: UIStackView!
    
    @IBOutlet var currentWindowLabel: UILabel!
    @IBOutlet var bestScoreLabel: UILabel!
    
    @IBOutlet var translationLabel: UILabel!
    @IBOutlet var totalTranslationLabel: UILabel!
    @IBOutlet var remoteConfigLabel: UILabel!
    
    @IBOutlet var framesEvaluatedLabel: UILabel!
    @IBOutlet var liveScoreLabel: UILabel!

    @IBOutlet var framesRejectedLabel: UILabel!
    @IBOutlet var currentFilterRejectionLabel: UILabel!
    
    @IBOutlet var eulerAnglesLabel: UILabel!
    @IBOutlet var eulerAngleSpreadsLabel: UILabel!
    
    @IBOutlet var lastResultLabel: UILabel!
    @IBOutlet var errorsLabel: UILabel!
    @IBOutlet var deviceLocationLabel: UILabel!
        
    private var windowTimer: Timer?
    private var windowStart: Date?
    
    private var lastFrameTimestamp: TimeInterval = 0.0
    private var rejectionLabels: [FMFrameRejectionReason: UILabel] = [:]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        sdkVersionLabel.text = "Fantasmo SDK \(FMSDKInfo.fullVersion)"
        remoteConfigLabel.text = "Remote Config: \(RemoteConfig.config().remoteConfigId)"
        startWindowTimer()
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
    
    public func update(frameEvaluationStatistics: FMFrameEvaluationStatistics) {
        let window = frameEvaluationStatistics.windows.last
        windowStart = window?.start
        framesEvaluatedLabel.text = "Frames evaluated: \(window?.evaluations ?? 0)"
        
        // update live score
        var liveScoreText = "Live score: "
        if let liveScore = window?.currentScore {
            liveScoreText += String(format: "%.5f", liveScore)
        } else {
            liveScoreText += "n/a"
        }
        liveScoreLabel.text = liveScoreText
        
        // update window best score
        var bestScoreText = "Best score: "
        if let currentBestScore = window?.currentBestScore {
            bestScoreText += String(format: "%.5f", currentBestScore)
        } else {
            bestScoreText += "n/a"
        }
        bestScoreLabel.text = bestScoreText
        
        // update window filter rejections
        framesRejectedLabel.text = "Frames rejected: \(window?.rejections ?? 0)"
        currentFilterRejectionLabel.text = window?.currentFilterRejection?.rawValue ?? ""
        
        // update total frame rejections
        for (reason, total) in frameEvaluationStatistics.rejectionReasons {
            guard total > 0 else {
                continue
            }
            var label: UILabel! = rejectionLabels[reason]
            if label == nil {
                label = UILabel()
                label.font = UIFont.systemFont(ofSize: 16.0)
                label.textColor = .black
                label.backgroundColor = .init(white: 1.0, alpha: 0.3)
                rejectionStackView.addArrangedSubview(label)
                rejectionLabels[reason] = label
            }
            label.text = "\t\(reason.rawValue): \(total)"
        }
        totalRejectionsLabel.text = "Total frame rejections: \(frameEvaluationStatistics.totalRejections)"
    }
    
    public func update(activeUploads: [FMFrame]) {
        uploadStackView.arrangedSubviews.forEach { sv in
            sv.removeFromSuperview()
        }
        for frame in activeUploads {
            let uploadText = "Uploading... "
            var infoText = "Score: "
            if let score = frame.evaluation?.score {
                infoText += String(format: "%.5f", score)
            } else {
                infoText += "n/a"
            }
            if let gamma = frame.enhancedImageGamma {
                infoText += String(format: ", Gamma: %.5f", gamma)
            }
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 16.0)
            label.textColor = .black
            label.backgroundColor = .init(white: 1.0, alpha: 0.3)
            label.attributedText = highlightString(uploadText, in: "\(uploadText) [\(infoText)]", color: .green)
            uploadStackView.addArrangedSubview(label)
        }
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
            errorText += "\tLast error: \(lastErrorDescription)"
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
    
    private func startWindowTimer() {
        windowTimer?.invalidate()
        windowTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] _ in
            guard let label = self?.currentWindowLabel else {
                return
            }
            var timeElapsed: TimeInterval = 0
            if let windowStart = self?.windowStart {
                timeElapsed = Date().timeIntervalSince(windowStart)
            }
            label.text = String(format: "Current window: %.1fs", timeElapsed)
        })
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
