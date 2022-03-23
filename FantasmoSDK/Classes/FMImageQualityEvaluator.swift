//
//  FMImageQualityEvaluator.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 18.11.21.
//

import ARKit
import CoreML
import VideoToolbox


class FMImageQualityEvaluator {
    /// Factory constructor, returns the CoreML evaluator if supported
    static func makeEvaluator() -> FMFrameEvaluator {
        if #available(iOS 13.0, *) {
            return FMImageQualityEvaluatorCoreML()
        } else {
            return FMImageQualityEvaluatorNotSupported()
        }
    }
}


/// Evaluator class for iOS versions that don't support CoreML
class FMImageQualityEvaluatorNotSupported: FMFrameEvaluator {
    func evaluate(frame: FMFrame) -> FMFrameEvaluation {
        // Return with a score of 1.0 so the frame is always accepted
        let imageQualityUserInfo = FMImageQualityUserInfo(error: "device not supported")
        return FMFrameEvaluation(type: .imageQuality, score: 1, time: 0, imageQualityUserInfo: imageQualityUserInfo)
    }
}

/// CoreML image quality evaluator
@available(iOS 13.0, *)
class FMImageQualityEvaluatorCoreML: FMFrameEvaluator {
    
    enum Error: String {
        case failedToCreateModel
        case failedToCreateInputArray
        case failedToResizePixelBuffer
        case invalidFeatureValue
        case noPrediction
    }
    
    private let mlModel: ImageQualityModel?
    private let mlInputShape: [NSNumber] = [1, 3, 320, 240]
    private let imageWidth: Int = 320
    private let imageHeight: Int = 240
    private var isCheckingForUpdates: Bool = false
    
    public private(set) var modelVersion: String?
        
    init() {        
        let fileManager = FileManager.default
        let modelName = String(describing: ImageQualityModel.self)
        let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let currentModelLocation = appSupportDirectory.appendingPathComponent(modelName).appendingPathExtension("mlmodelc")
        
        defer {
            if let mlModel = mlModel, let version = mlModel.model.modelDescription.metadata[MLModelMetadataKey.versionString] as? String {
                modelVersion = version
                log.info("loaded image quality model \(version)")
            }
        }
        
        // Check if we have a downloaded model
        if fileManager.fileExists(atPath: currentModelLocation.path) {
            do {
                // Attempt to load the downloaded model
                mlModel = try ImageQualityModel(contentsOf: currentModelLocation)
                return
            } catch {
                log.error("error loading downloaded model: \(error.localizedDescription)")
                try? fileManager.removeItem(at: currentModelLocation)
            }
        }
        
        // Load the default bundled model
        mlModel = try? ImageQualityModel(configuration: MLModelConfiguration())
    }
    
    func makeResizedPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> CGContext? {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        guard let cgImage = cgImage else {
            return nil
        }
        
        let bytesPerRow = 4 * imageWidth
        let newPixelBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bytesPerRow * imageHeight)
        guard let context = CGContext(
            data: newPixelBuffer,
            width: imageWidth,
            height: imageHeight,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            return nil
        }
        
        let targetRect = CGRect(x: 0, y: 0, width: CGFloat(imageWidth), height: CGFloat(imageHeight))
        context.draw(cgImage, in: targetRect)
        return context
    }
    
    func evaluate(frame: FMFrame) -> FMFrameEvaluation {
        guard let mlModel = mlModel else {
            log.error("failed to create model")
            return makeEvaluation(error: .failedToCreateModel)
        }
        guard let mlInputArray = try? MLMultiArray(shape: mlInputShape, dataType: MLMultiArrayDataType.float32) else {
            log.error("failed to create input array")
            return makeEvaluation(error: .failedToCreateInputArray)
        }
        
        let evaluationStart = Date()
        
        // Resize the pixel buffer down to the expected input size, use the enhanced image if available
        guard let resizedPixelBufferContext = makeResizedPixelBuffer(frame.enhancedImageOrCapturedImage),
              let resizedPixelBuffer = UnsafePointer<UInt8>(OpaquePointer(resizedPixelBufferContext.data))
        else {
            log.error("failed to resize pixel buffer")
            return makeEvaluation(error: .failedToResizePixelBuffer)
        }
        defer {
            resizedPixelBuffer.deallocate()
        }
        
        // Get a pointer to the input array contents
        let mlInputArrayPointer = UnsafeMutablePointer<Float32>(OpaquePointer(mlInputArray.dataPointer))
        let bytesPerRow = imageWidth * 4
        for y in 0..<imageHeight {
            for x in 0..<imageWidth {
                let index = x * 4 + y * bytesPerRow
                
                // convert rgb values to 0.0 - 1.0
                var r = Float(resizedPixelBuffer[index + 1]) / 255.0
                var g = Float(resizedPixelBuffer[index + 2]) / 255.0
                var b = Float(resizedPixelBuffer[index + 3]) / 255.0
                                                
                // subtract mean, stddev normalization
                r = (r - 0.485) / 0.229
                g = (g - 0.456) / 0.224
                b = (b - 0.406) / 0.225
                
                // rotate 90 degrees clockwise
                let w = imageHeight - 1 - y
                let h = x

                // calculate the destination indexes for each channel
                let rIndex = 0 * imageHeight * imageWidth + h * imageHeight + w
                let gIndex = 1 * imageHeight * imageWidth + h * imageHeight + w
                let bIndex = 2 * imageHeight * imageWidth + h * imageHeight + w
                
                // add the rgb values to the input array
                mlInputArrayPointer[rIndex] = r
                mlInputArrayPointer[gIndex] = g
                mlInputArrayPointer[bIndex] = b
            }
        }
        
        let imageQualityInput = ImageQualityModelInput(input_1: mlInputArray)
        guard let prediction = try? mlModel.prediction(input: imageQualityInput) else {
            log.error("no prediction")
            return makeEvaluation(error: .noPrediction)
        }
        
        guard let featureName = prediction.featureNames.first, let featureValue = prediction.featureValue(for: featureName)?.multiArrayValue, featureValue.count == 2 else {
            log.error("invalid feature value")
            return makeEvaluation(error: .invalidFeatureValue)
        }

        let y1Exp = exp(Float32(truncating: featureValue[0]))
        let y2Exp = exp(Float32(truncating: featureValue[1]))
        let score = 1.0 / (1.0 + y2Exp / y1Exp)
        
        let evaluationTime = Date().timeIntervalSince(evaluationStart)
        
        return makeEvaluation(score: score, time: evaluationTime)
    }
    
    func makeEvaluation(score: Float, time: TimeInterval) -> FMFrameEvaluation {
        let imageQualityUserInfo = FMImageQualityUserInfo(modelVersion: modelVersion)
        return FMFrameEvaluation(type: .imageQuality, score: score, time: time, imageQualityUserInfo: imageQualityUserInfo)
    }
    
    func makeEvaluation(error: Error) -> FMFrameEvaluation {
        // Return with a score of 1.0 so the frame is always accepted
        let imageQualityUserInfo = FMImageQualityUserInfo(modelVersion: modelVersion, error: error.rawValue)
        return FMFrameEvaluation(type: .imageQuality, score: 1, time: 0, imageQualityUserInfo: imageQualityUserInfo)
    }
}
