//
//  MockQRCodeDetector.swift
//  FantasmoSDKTestHarness
//
//  Created by Nick Jensen on 05.11.21.
//

import Foundation
import FantasmoSDK
import CoreImage
import UIKit

class MockQRCodeDetector: FMQRCodeDetector {
    
    var detectedQRCode: CIQRCodeFeature?
        
    private let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
    
    func checkAsyncThrottled(_ pixelBuffer: CVPixelBuffer) {
        guard detectedQRCode == nil else {
            return
        }
        guard let cgImage = UIImage(named: "qr-code")?.cgImage else {
            return
        }
        let ciImage = CIImage(cgImage: cgImage)
        detectedQRCode = detector?.features(in: ciImage).first as? CIQRCodeFeature
        if detectedQRCode == nil {
            fatalError("Failed to detect mock QR code")
        }
    }
}
