//
//  FMBlurFilter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit
import Metal
import MetalPerformanceShaders
import MetalKit
import VideoToolbox

class FMBlurFilter: FMFrameFilter {
    
    var variance = 0
    var varianceAverager = MovingAverage()
    var averageVariance: Double {
        varianceAverager.average
    }

    var varianceThreshold = 4.0 // empirically determined
    var suddenDropThreshold = 2.0 // empirically determined
        
    var throughputAverager = MovingAverage(period: 8)
    var averageThroughput: Double {
        throughputAverager.average
    }
    
    let metalDevice = MTLCreateSystemDefaultDevice()
    let metalCommandQueue: MTLCommandQueue?

    init() {
        metalCommandQueue = metalDevice?.makeCommandQueue()
    }
    
    func accepts(_ frame: ARFrame) -> FMFilterResult {
        variance = calculateVariance(frame: frame)
        _ = varianceAverager.addSample(value: Double(variance))
        
        var isLowVariance = false
        var isBlurry = false

        let isBelowThreshold = Double(variance) < varianceThreshold
        let isSuddenDrop = Double(variance) < (averageVariance - suddenDropThreshold)
        isLowVariance = isBelowThreshold || isSuddenDrop
        
        if isLowVariance {
            _ = throughputAverager.addSample(value: 0.0)
        } else {
            _ = throughputAverager.addSample(value: 1.0)
        }
        
        // if not enough images are passing, pass regardless of variance
        if averageThroughput < 0.25 {
            isBlurry = false
        } else {
            isBlurry = isLowVariance
        }
        
        return isBlurry ? .rejected(reason: .movingTooFast) : .accepted
    }
    
    func calculateVariance(frame: ARFrame) -> Int {
        guard let metalDevice = metalDevice, let metalCommandBuffer = self.metalCommandQueue?.makeCommandBuffer() else {
            return 0
        }
        
        // Set up shaders
        let laplacian = MPSImageLaplacian(device: metalDevice)
        let meanAndVariance = MPSImageStatisticsMeanAndVariance(device: metalDevice)
        
        // load frame buffer as texture
        let pixelBuffer = frame.capturedImage
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        let textureLoader = MTKTextureLoader(device: metalDevice)
        let sourceTexture = try! textureLoader.newTexture(cgImage: cgImage!, options: nil)
        
        // set up destination texture
        let laplacianTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: sourceTexture.pixelFormat, width: sourceTexture.width, height: sourceTexture.height, mipmapped: false)
        laplacianTextureDescriptor.usage = [.shaderWrite, .shaderRead]
        let lapTex = metalDevice.makeTexture(descriptor: laplacianTextureDescriptor)!
        
        // encode the laplacian command
        laplacian.encode(commandBuffer: metalCommandBuffer, sourceTexture: sourceTexture, destinationTexture: lapTex)
        
        // set up destinaction texture
        let varianceTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: sourceTexture.pixelFormat, width: 2, height: 1, mipmapped: false)
        varianceTextureDescriptor.usage = [.shaderWrite, .shaderRead]
        let varianceTexture = metalDevice.makeTexture(descriptor: varianceTextureDescriptor)!
        
        // encode the mean and variance command
        meanAndVariance.encode(commandBuffer: metalCommandBuffer, sourceTexture: lapTex, destinationTexture: varianceTexture)
        
        // run the buffer
        metalCommandBuffer.commit()
        metalCommandBuffer.waitUntilCompleted()
        
        // grab results
        var result = [Int8](repeatElement(0, count: 2))
        let region = MTLRegionMake2D(0, 0, 2, 1)
        varianceTexture.getBytes(&result, bytesPerRow: 1 * 2 * 4, from: region, mipmapLevel: 0)
        
        return Int(result.last ?? 0)
    }
}
