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
    
    var variance: Float = 0.0
    var varianceAverager = MovingAverage()
    var averageVariance: Float {
        varianceAverager.average
    }

    var varianceThreshold: Float = 250.0 // empirically determined
    var suddenDropThreshold: Float = 0.4 // empirically determined
        
    var throughputAverager = MovingAverage(period: 8)
    var averageThroughput: Float {
        throughputAverager.average
    }
    
    let metalDevice = MTLCreateSystemDefaultDevice()
    let metalCommandQueue: MTLCommandQueue?

    init() {
        metalCommandQueue = metalDevice?.makeCommandQueue()
    }
    
    func accepts(_ frame: ARFrame) -> FMFrameFilterResult {
        variance = calculateVariance(frame: frame)
        _ = varianceAverager.addSample(value: variance)
        
        var isLowVariance = false
        var isBlurry = false

        let isBelowThreshold = variance < varianceThreshold
        let isSuddenDrop = variance < (averageVariance * suddenDropThreshold)
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
        
        return isBlurry ? .rejected(reason: .imageTooBlurry) : .accepted
    }
    
    func calculateVariance(frame: ARFrame) -> Float {
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

        // convert image to black-and-white
        let srcColorSpace = CGColorSpaceCreateDeviceRGB();
        let dstColorSpace = CGColorSpaceCreateDeviceGray();
        let conversionInfo = CGColorConversionInfo(src: srcColorSpace, dst: dstColorSpace);
        let conversion = MPSImageConversion(device: metalDevice,
                                            srcAlpha: .alphaIsOne,
                                            destAlpha: .alphaIsOne,
                                            backgroundColor: nil,
                                            conversionInfo: conversionInfo)
        let grayTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r16Unorm, width: sourceTexture.width, height: sourceTexture.height, mipmapped: false)
        grayTextureDescriptor.usage = [.shaderWrite, .shaderRead]
        let grayTexture = metalDevice.makeTexture(descriptor: grayTextureDescriptor)!
        conversion.encode(commandBuffer: metalCommandBuffer, sourceTexture: sourceTexture, destinationTexture: grayTexture)

        // set up destination texture
        let laplacianTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: grayTexture.pixelFormat, width: grayTexture.width, height: grayTexture.height, mipmapped: false)
        laplacianTextureDescriptor.usage = [.shaderWrite, .shaderRead]
        let lapTexture = metalDevice.makeTexture(descriptor: laplacianTextureDescriptor)!

        // encode the laplacian command
        laplacian.encode(commandBuffer: metalCommandBuffer, sourceTexture: grayTexture, destinationTexture: lapTexture)

        // set up destination texture
        let varianceTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r32Float, width: 2, height: 1, mipmapped: false)
        varianceTextureDescriptor.usage = [.shaderWrite, .shaderRead]
        let varianceTexture = metalDevice.makeTexture(descriptor: varianceTextureDescriptor)!

        // encode the mean and variance command
        meanAndVariance.encode(commandBuffer: metalCommandBuffer, sourceTexture: lapTexture, destinationTexture: varianceTexture)

        // run the buffer
        metalCommandBuffer.commit()
        metalCommandBuffer.waitUntilCompleted()

        // grab results
        var result = [Float](repeatElement(0, count: 2))
        let region = MTLRegionMake2D(0, 0, 2, 1)
        varianceTexture.getBytes(&result, bytesPerRow: 1 * 2 * 4, from: region, mipmapLevel: 0)

        return Float(result.last! * 255.0 * 255.0)
    }
}
