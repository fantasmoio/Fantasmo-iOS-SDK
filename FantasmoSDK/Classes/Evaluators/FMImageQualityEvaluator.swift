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
    
    /// Input shape is portrait oriented `[1, channels, height, width]`.
    private let mlInputShape: [NSNumber] = [1, 3, 320, 240]
    
    /// Reusable CIContext used to resize source pixel buffers.
    private let ciContext: CIContext
    
    /// Reusable CIFilter used to resize source pixel buffers.
    private let ciResizeFilter: CIFilter?

    /// The version string of the ML model instance, or nil if failed to load.
    private(set) var modelVersion: String?
    
    /// Source pixel buffers will be resized to this width.
    private(set) var resizedPixelBufferWidth: Int = 320
    
    /// Source pixel buffers will be resized to this height.
    private(set) var resizedPixelBufferHeight: Int = 240
    
    /// Specifies whether source pixel buffers are rotated 90° counterclockwise, this is true for frames coming from ARKit.
    var sourcePixelBuffersAreRotated = true {
        didSet {
            resizedPixelBufferWidth = sourcePixelBuffersAreRotated ? 320 : 240
            resizedPixelBufferHeight = sourcePixelBuffersAreRotated ? 240 : 320
        }
    }
    
    init() {
        // Create a reusable context for resizing pixel buffers
        let isMetalSupported = MTLCreateSystemDefaultDevice() != nil
        ciContext = CIContext(options: [.useSoftwareRenderer: !isMetalSupported])
        // Create a reusable bicubic scaling filter
        ciResizeFilter = CIFilter(name: "CIBicubicScaleTransform")
        // The parameter C is from the bicubic convolution algorithm
        // https://en.wikipedia.org/wiki/Bicubic_interpolation#Bicubic_convolution_algorithm
        // The value 0.5 is used by PIL and produces scores closer to our reference
        ciResizeFilter?.setValue(NSNumber(0.5), forKey: "inputC")
        
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
    
    func makeResizedPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> UnsafeMutablePointer<UInt8>? {
        guard let ciResizeFilter = ciResizeFilter else {
            return nil
        }
        
        let targetSize = CGSize(width: resizedPixelBufferWidth, height: resizedPixelBufferHeight)
        let originalSize = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
        let inputScale = targetSize.height / originalSize.height
        let inputAspectRatio = targetSize.width / (originalSize.width * inputScale)
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        ciResizeFilter.setValue(ciImage, forKey: kCIInputImageKey)
        ciResizeFilter.setValue(inputScale, forKey: kCIInputScaleKey)
        ciResizeFilter.setValue(inputAspectRatio, forKey: kCIInputAspectRatioKey)
        
        guard let outputImage = ciResizeFilter.outputImage else {
            return nil
        }
        
        let bytesPerRow = 4 * resizedPixelBufferWidth
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let resizedBounds = CGRect(origin: .zero, size: targetSize)
        let resizedPixelBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bytesPerRow * resizedPixelBufferHeight)
        ciContext.render(outputImage, toBitmap: resizedPixelBuffer, rowBytes: bytesPerRow, bounds: resizedBounds, format: .ARGB8, colorSpace: colorSpace)
                
        return resizedPixelBuffer
    }
    
    func makeInputArray() -> MLMultiArray? {
        return try? MLMultiArray(shape: mlInputShape, dataType: MLMultiArrayDataType.float32)
    }
    
    func evaluate(frame: FMFrame) -> FMFrameEvaluation {
        guard let mlModel = mlModel else {
            log.error("failed to create model")
            return makeEvaluation(error: .failedToCreateModel)
        }
        guard let mlInputArray = makeInputArray() else {
            log.error("failed to create input array")
            return makeEvaluation(error: .failedToCreateInputArray)
        }
        
        let evaluationStart = Date()
        // get the source pixel buffer, use the enhanced image buffer if available
        let sourcePixelBuffer = frame.enhancedImageOrCapturedImage
        
        // resize the source pixel buffer down to the required input size
        guard let resizedPixelBuffer = makeResizedPixelBuffer(sourcePixelBuffer) else {
            log.error("failed to resize pixel buffer")
            return makeEvaluation(error: .failedToResizePixelBuffer)
        }
        defer {
            resizedPixelBuffer.deallocate()
        }
        
        // populate the input array from the resized pixel buffer
        populateInputArray(mlInputArray, from: resizedPixelBuffer)
        
        // make the prediction
        let imageQualityInput = ImageQualityModelInput(input_1: mlInputArray)
        guard let prediction = try? mlModel.prediction(input: imageQualityInput) else {
            log.error("no prediction")
            return makeEvaluation(error: .noPrediction)
        }
        
        // get the prediction result
        guard let featureName = prediction.featureNames.first, let featureValue = prediction.featureValue(for: featureName)?.multiArrayValue, featureValue.count == 2 else {
            log.error("invalid feature value")
            return makeEvaluation(error: .invalidFeatureValue)
        }
        
        // calculate score from the prediction result
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
    
    func populateInputArray(_ inputArray: MLMultiArray, from resizedPixelBuffer: UnsafeMutablePointer<UInt8>) {
        // get our ml input array dimensions
        let inputHeight = inputArray.shape[2].intValue
        let inputWidth = inputArray.shape[3].intValue
        
        // get a pointer to the ml input array contents
        let inputArrayPointer = UnsafeMutablePointer<Float32>(OpaquePointer(inputArray.dataPointer))
        
        // iterate over the pixels of the resized source pixel buffer
        let bytesPerRow = resizedPixelBufferWidth * 4
        for y in 0..<resizedPixelBufferHeight {
            for x in 0..<resizedPixelBufferWidth {
                let index = x * 4 + y * bytesPerRow
                
                // convert each source rgb value to 0.0 - 1.0
                var r = Float(resizedPixelBuffer[index + 1]) / 255.0
                var g = Float(resizedPixelBuffer[index + 2]) / 255.0
                var b = Float(resizedPixelBuffer[index + 3]) / 255.0
                                                
                // subtract mean, stddev normalization
                r = (r - 0.485) / 0.229
                g = (g - 0.456) / 0.224
                b = (b - 0.406) / 0.225
                                
                let w: Int
                let h: Int
                if sourcePixelBuffersAreRotated {
                    // the source pixel buffer is rotated 90° counterclockwise, that means -
                    // the first row of our input array is from the bottom-left to the top-left of the source pixel buffer and
                    // the last row of our input array is from the bottom-right to the top-right of the source pixel buffer
                    w = resizedPixelBufferHeight - 1 - y
                    h = x
                } else {
                    // the source pixel buffer is already in portrait, which is what the model requires
                    w = x
                    h = y
                }
                
                // calculate the destination index for each value in our input array
                let rIndex = 0 * inputWidth * inputHeight + h * inputWidth + w
                let gIndex = 1 * inputWidth * inputHeight + h * inputWidth + w
                let bIndex = 2 * inputWidth * inputHeight + h * inputWidth + w
                
                // add the rgb values to the input array
                inputArrayPointer[rIndex] = r
                inputArrayPointer[gIndex] = g
                inputArrayPointer[bIndex] = b
            }
        }
    }
}
