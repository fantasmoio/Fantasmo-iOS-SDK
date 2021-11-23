//
//  ImageQualityEstimator.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 11.11.21.
//

import Foundation
import CoreVideo

class ImageQualityEstimator {
    static func makeEstimator() -> ImageQualityEstimatorProtocol {
        if #available(iOS 13.0, *) {
            return ImageQualityEstimatorCoreML()
        } else {
            return ImageQualityEstimatorDeviceNotSupported()
        }
    }
}

protocol ImageQualityEstimatorProtocol {
    func estimateImageQuality(from pixelBuffer: CVPixelBuffer) -> ImageQualityEstimationResult
}

class ImageQualityEstimatorDeviceNotSupported: ImageQualityEstimatorProtocol {
    func estimateImageQuality(from pixelBuffer: CVPixelBuffer) -> ImageQualityEstimationResult {
        return .error(message: "Device not supported.")
    }
}
