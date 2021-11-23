//
//  ImageQualityEstimatorCoreML.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 11.11.21.
//

import Foundation
import CoreML
import CoreVideo
import VideoToolbox
import UIKit

@available(iOS 13.0, *)
class ImageQualityEstimatorCoreML: ImageQualityEstimatorProtocol {
    
    let mlModel = try? ImageQualityModel(configuration: MLModelConfiguration())
    let mlInputShape: [NSNumber] = [1, 3, 320, 240]
    let imageWidth: Int = 320
    let imageHeight: Int = 240
    
    func makeResizedPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> UnsafeMutablePointer<UInt8>? {
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
    
    func estimateImageQuality(from pixelBuffer: CVPixelBuffer) -> ImageQualityEstimationResult {
        guard let mlModel = mlModel else {
            return .error(message: "Failed to create CoreML model.")
        }
        guard let mlInputArray = try? MLMultiArray(shape: mlInputShape, dataType: MLMultiArrayDataType.float32) else {
            return .error(message: "Failed to create input MLMultiArray.")
        }
        guard let resizedPixelBuffer = makeResizedPixelBuffer(pixelBuffer) else {
            return .error(message: "Failed to resize pixel buffer.")
        }
                
        // var originalBytes = Array<[String]>(repeating: Array<String>(repeating: "", count: 320), count: 240)
        // var rotatedBytes = Array<[String]>(repeating: Array<String>(repeating: "", count: 240), count: 320)
        
        // Get a pointer to the multiarray’s contents.
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

                // add the rgb values to the input array
                let rIndex = 0 * imageHeight * imageWidth + h * imageHeight + w
                let gIndex = 1 * imageHeight * imageWidth + h * imageHeight + w
                let bIndex = 2 * imageHeight * imageWidth + h * imageHeight + w

                mlInputArrayPointer[rIndex] = r
                mlInputArrayPointer[gIndex] = g
                mlInputArrayPointer[bIndex] = b
                
                // let rStr = String(format: "%02X", resizedPixelBuffer[index + 1])
                // let gStr = String(format: "%02X", resizedPixelBuffer[index + 2])
                // let bStr = String(format: "%02X", resizedPixelBuffer[index + 3])
                // originalBytes[y][x] = "0x\(bStr)\(gStr)\(rStr)"
                // rotatedBytes[h][w] = "0x\(bStr)\(gStr)\(rStr)"
            }
        }
        
        resizedPixelBuffer.deallocate()
        
        /*
        let originalString = originalBytes.map({ $0.joined(separator: " ") }).joined(separator: "\n")
        let originalPath = NSString("~/Documents/original-bytes.txt").expandingTildeInPath
        print("originalPath: \(originalPath)")
        try! originalString.data(using: .utf8)!.write(to: URL(fileURLWithPath: originalPath))
        
        let rotatedString = rotatedBytes.map({ $0.joined(separator: " ") }).joined(separator: "\n")
        let rotatedPath = NSString("~/Documents/rotated-bytes.txt").expandingTildeInPath
        print("rotatedPath: \(rotatedPath)")
        try! rotatedString.data(using: .utf8)!.write(to: URL(fileURLWithPath: rotatedPath))

        var mlInputString = ""
        for channel in 0..<3 {
            for row in 0..<320 {
                for col in 0..<240 {
                    let key = [0, channel, row, col] as [NSNumber]
                    let numberValue = mlInputArray[key]
                    mlInputString += numberValue.stringValue + " "
                }
            }
        }

        let mlInputPath = NSString("~/Documents/ml-input-array.txt").expandingTildeInPath
        print("mlInputPath: \(mlInputPath)")
        try! mlInputString.data(using: .utf8)!.write(to: URL(fileURLWithPath: mlInputPath))
         */
         
        let imageQualityInput = ImageQualityModelInput(input_1: mlInputArray)
        guard let prediction = try? mlModel.prediction(input: imageQualityInput) else {
            return .unknown
        }

        guard let featureName = prediction.featureNames.first, let featureValue = prediction.featureValue(for: featureName)?.multiArrayValue, featureValue.count == 2 else {
            return .error(message: "Invalid feature value.")
        }

        let y1Exp = exp(Float32(truncating: featureValue[0]))
        let y2Exp = exp(Float32(truncating: featureValue[1]))
        let score = 1.0 / (1.0 + y2Exp / y1Exp)
        
        return .estimate(score: score)
    }
}
