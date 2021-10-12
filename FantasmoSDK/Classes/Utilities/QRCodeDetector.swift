//
//  QRCodeDetector.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 30.09.21.
//

import Foundation
import CoreImage
import ARKit

class QRCodeDetector {
    
    static let minDetectableSize: CGFloat = 250.0
    
    public var detectedQRCode: CIQRCodeFeature?
        
    private let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
    
    private let checksAllowedPerSecond: TimeInterval = 3.0
    
    private var isChecking: Bool = false
    
    private var lastFrameTimestamp: TimeInterval = 0.0
    
    func checkFrameAsyncThrottled(_ frame: ARFrame) {
        guard !isChecking, detectedQRCode == nil else {
            return
        }
        let checkAllowed = frame.timestamp - lastFrameTimestamp > (1.0 / checksAllowedPerSecond)
        guard checkAllowed else {
            return
        }
        lastFrameTimestamp = frame.timestamp
        isChecking = true
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let image = CIImage(cvPixelBuffer: frame.capturedImage)
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
