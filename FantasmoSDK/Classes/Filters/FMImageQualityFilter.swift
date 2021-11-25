//
//  FMImageQualityFilter.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 18.11.21.
//

import ARKit
import CoreML
import VideoToolbox

@available(iOS 13.0, *)
class FMImageQualityFilter: FMFrameFilter {
        
    private let mlModel: ImageQualityModel?
    private let mlInputShape: [NSNumber] = [1, 3, 320, 240]
    private let imageWidth: Int = 320
    private let imageHeight: Int = 240
    private var isCheckingForUpdates: Bool = false
    
    public private(set) var scoreThreshold: Float
    public private(set) var modelVersion: String?
    public private(set) var lastImageQualityScore: Float = 0.0
    
    init(scoreThreshold: Float) {
        self.scoreThreshold = scoreThreshold
        
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
    
    private func makeResizedPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> UnsafeMutablePointer<UInt8>? {
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
        return newPixelBuffer
    }
    
    public func accepts(_ frame: FMFrame) -> FMFrameFilterResult {
        guard let mlModel = mlModel else {
            log.error("failed to create model")
            return .accepted
        }
        guard let mlInputArray = try? MLMultiArray(shape: mlInputShape, dataType: MLMultiArrayDataType.float32) else {
            log.error("failed to create input array")
            return .accepted
        }
        
        // Resize the pixel buffer down to the expected input size
        guard let resizedPixelBuffer = makeResizedPixelBuffer(frame.capturedImage) else {
            log.error("failed to resize pixel buffer")
            return .accepted
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
            return .accepted
        }
        
        guard let featureName = prediction.featureNames.first, let featureValue = prediction.featureValue(for: featureName)?.multiArrayValue, featureValue.count == 2 else {
            log.error("invalid feature value")
            return .accepted
        }

        let y1Exp = exp(Float32(truncating: featureValue[0]))
        let y2Exp = exp(Float32(truncating: featureValue[1]))
        let score = 1.0 / (1.0 + y2Exp / y1Exp)
        
        lastImageQualityScore = score
        
        return score >= scoreThreshold ? .accepted : .rejected(reason: .imageQualityScoreBelowThreshold)
    }
}
