//
//  QRCodeDetector.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 30.09.21.
//

import Foundation
import CoreImage

class QRCodeDetector: FMQRCodeDetector {
    
    static let minDetectableSize: CGFloat = 0.0
    
    public var detectedQRCode: CIQRCodeFeature?
        
    private let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
    
    private let checksAllowedPerSecond: TimeInterval = 3.0
    
    private var isChecking: Bool = false
    
    private var lastCheckTimestamp: TimeInterval = 0.0
    
    func checkAsyncThrottled(_ pixelBuffer: CVPixelBuffer) {
        guard !isChecking, detectedQRCode == nil else {
            return
        }
        let timestampNow = Date().timeIntervalSince1970
        let checkAllowed = timestampNow - lastCheckTimestamp > (1.0 / checksAllowedPerSecond)
        guard checkAllowed else {
            return
        }
        lastCheckTimestamp = timestampNow
        isChecking = true
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let image = CIImage(cvPixelBuffer: pixelBuffer)
            let qrCode = self?.detector?.features(in: image).first as? CIQRCodeFeature
            DispatchQueue.main.async {
                self?.isChecking = false
                if let qrCode = qrCode, max(qrCode.bounds.width, qrCode.bounds.height) >= QRCodeDetector.minDetectableSize {
                    self?.detectedQRCode = qrCode
                } else {
                    self?.detectedQRCode = nil
                }
            }
        }
    }
}
