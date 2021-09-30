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
            
    var detectedQRCodeFeature: CIQRCodeFeature?
    
    private let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
    
    private var isChecking: Bool = false
    
    func checkFrameAsync(_ frame: ARFrame) {
        guard !isChecking, detectedQRCodeFeature == nil else {
            return
        }
        isChecking = true
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let image = CIImage(cvPixelBuffer: frame.capturedImage)
            let qrCodeFeature = self?.detector?.features(in: image).first as? CIQRCodeFeature
            DispatchQueue.main.async {
                self?.detectedQRCodeFeature = qrCodeFeature
                self?.isChecking = false
            }
        }
    }
}
