//
//  FMBlurFilter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit
import MetalPerformanceShaders

/// Rejects low variance images. Because an absolute threshold is not always
/// appropriate, also rejects frames that have a lower than average variance.
/// In a low-feature situation where variance continues to be low, the filter
/// effectively deactivates so that some frames will still get through.
class FMBlurFilter: FMFrameFilter {
    
    var variance: Float = 0.0
    var varianceAverager = MovingAverage()
    var averageVariance: Float {
        varianceAverager.average
    }

    let varianceThreshold: Float
    let suddenDropThreshold: Float
    let averageThroughputThreshold: Float
    
    var throughputAverager = MovingAverage(period: 8)
    var averageThroughput: Float {
        throughputAverager.average
    }
    
    let metalDevice = MTLCreateSystemDefaultDevice()
    let metalCommandQueue: MTLCommandQueue?
    var metalTextureCache: CVMetalTextureCache?

    init(varianceThreshold: Float, suddenDropThreshold: Float, averageThroughputThreshold: Float) {
        self.varianceThreshold = varianceThreshold
        self.suddenDropThreshold = suddenDropThreshold
        self.averageThroughputThreshold = averageThroughputThreshold
        metalCommandQueue = metalDevice?.makeCommandQueue()
        if let metalDevice = metalDevice {
            // create a texture cache for CV-backed metal textures
            CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, metalDevice, nil, &metalTextureCache)
        }
    }
    
    func accepts(_ frame: FMFrame) -> FMFrameFilterResult {
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
        if averageThroughput < averageThroughputThreshold {
            isBlurry = false
        } else {
            isBlurry = isLowVariance
        }
        
        return isBlurry ? .rejected(reason: .imageTooBlurry) : .accepted
    }
    
    func calculateVariance(frame: FMFrame) -> Float {
        guard let metalDevice = metalDevice, let metalCommandBuffer = self.metalCommandQueue?.makeCommandBuffer() else {
            return 0
        }

        guard let grayTexture = getMetalTexture(from: frame.capturedImage, pixelFormat: .r8Unorm, planeIndex: 0) else {
            log.error("error getting luma texture from pixel buffer")
            return 0
        }
        
        // Set up shaders
        let laplacian = MPSImageLaplacian(device: metalDevice)
        let meanAndVariance = MPSImageStatisticsMeanAndVariance(device: metalDevice)
        
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
    
    private func getMetalTexture(from pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat, planeIndex: Int) -> MTLTexture? {
        // Expects `pixelBuffer` to be bi-planar YCbCr
        guard let metalTextureCache = metalTextureCache, CVPixelBufferGetPlaneCount(pixelBuffer) >= 2 else {
            return nil
        }
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
        var cvMetalTexture: CVMetalTexture?
        let status = CVMetalTextureCacheCreateTextureFromImage(nil,
                                                               metalTextureCache,
                                                               pixelBuffer,
                                                               nil,
                                                               pixelFormat,
                                                               width,
                                                               height,
                                                               planeIndex,
                                                               &cvMetalTexture)
        guard status == kCVReturnSuccess, let cvMetalTexture = cvMetalTexture else {
            return nil
        }
        return CVMetalTextureGetTexture(cvMetalTexture)
    }
}
