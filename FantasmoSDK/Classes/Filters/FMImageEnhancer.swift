//
//  FMImageEnhancer.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 26.01.22.
//

import Foundation
import Metal
import MetalPerformanceShaders
import ARKit
import CoreVideo
import VideoToolbox
import MetalKit

/// Utility for enhancing image contents of an `FMFrame` (currently) by applying gamma correction.
class FMImageEnhancer {
        
    private let device: MTLDevice
    private let library: MTLLibrary
    private let commandQueue: MTLCommandQueue
    private let calculateGammaCorrectionPipelineState: MTLComputePipelineState
    private let convertYCbCrToRGBPipelineState: MTLComputePipelineState
    private let textureCache: CVMetalTextureCache
    
    public var targetBrightness: Float
    
    
    /// Designated initializer.
    ///
    /// - Parameter targetBrightness: The target averge brightness from 0.0 - 1.0, to use when enhancing images.
    /// This value is used by `enhance(frame:)` when calculating gamma. If a frame's average brightness is at or
    /// above this value, then no gamma correction will be applied. If a frame's average brightness is below this
    /// value, then the gamma calculated will be that which raises the frame's average brightness to approximately
    /// this value. A higher `targetBrightness` will result in stronger gamma correction.
    init?(targetBrightness: Float) {
        self.targetBrightness = targetBrightness
        // create a metal device
        guard let device = MTLCreateSystemDefaultDevice() else {
            log.error("error creating metal device")
            return nil
        }
        self.device = device
        
        // create a metal command queue
        guard let commandQueue = device.makeCommandQueue() else {
            log.error("error creating metal command queue")
            return nil
        }
        self.commandQueue = commandQueue
        
        // load metal shaders from our framework library
        do {
            let bundle = Bundle(for: type(of: self))
            self.library = try device.makeDefaultLibrary(bundle: bundle)
        } catch {
            log.error("error creating metal library: \(error.localizedDescription)")
            return nil
        }
        
        // set up pipeline state for calculating gamma correction
        let calculateGammaCorrectionFunctionName = "calculate_gamma_correction"
        guard let calculateGammaCorrectionFunction = library.makeFunction(name: calculateGammaCorrectionFunctionName) else {
            log.error("unable to find compute shader: \(calculateGammaCorrectionFunctionName)")
            return nil
        }
        do {
            self.calculateGammaCorrectionPipelineState = try device.makeComputePipelineState(function: calculateGammaCorrectionFunction)
        } catch {
            log.error("error creating compute pipeline state for \(calculateGammaCorrectionFunctionName) - \(error.localizedDescription)")
            return nil
        }

        // set up pipeline state for converting ycbcr textures to rgb
        let convertYCbCrToRGBFunctionName = "convert_ycbcr_to_rgb"
        guard let convertYCbCrToRGBFunction = library.makeFunction(name: convertYCbCrToRGBFunctionName) else {
            log.error("unable to find compute shader: \(convertYCbCrToRGBFunctionName)")
            return nil
        }
        do {
            self.convertYCbCrToRGBPipelineState = try device.makeComputePipelineState(function: convertYCbCrToRGBFunction)
        } catch {
            log.error("error creating compute pipeline state for \(convertYCbCrToRGBFunctionName) - \(error.localizedDescription)")
            return nil
        }
        
        // create a texture cache for CV-backed metal textures
        var textureCache: CVMetalTextureCache?
        let cvReturn = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
        guard cvReturn == kCVReturnSuccess, let textureCache = textureCache else {
            log.error("error creating cv metal texture cache - code \(cvReturn)")
            return nil
        }
        self.textureCache = textureCache
    }

    
    /// Attempts to enhance the image contents of the supplied `FMFrame` (currently) by applying gamma correction.
    /// This function uses the `targetBrightness` value passed to the constructor, to calculate an appropriate gamma.
    /// If the gamma calculated is less than 1.0, a gamma-corrected copy of the frame's image will be assigned to the
    /// `enhancedImage` property on the frame.
    ///
    /// - Parameter frame: The frame whose `capturedImage` should be enhanced.
    ///
    /// Note: The frame's `capturedImage` pixel format must be bi-planar YCbCr with 4:2:0 subsampling. This is the default
    /// for pixel buffers coming from ARKit. The resulting `enchancedImage` pixel format will be BGRA32.
    func enhance(frame: FMFrame) {
        // create a new metal command buffer
        var commandBuffer: MTLCommandBuffer! = commandQueue.makeCommandBuffer()
        guard commandBuffer != nil else {
            log.error("error creating metal command buffer")
            return
        }
        
        // get luma (Y) and chroma (CbCr) metal textures
        let capturedImage = frame.capturedImage
        guard let yTexture = getMetalTexture(from: capturedImage, pixelFormat: .r8Unorm, planeIndex: 0),
              let cbcrTexture = getMetalTexture(from: capturedImage, pixelFormat: .rg8Unorm, planeIndex: 1)
        else {
            log.error("error getting luma and chroma textures from pixel buffer")
            return
        }
                
        // calculate histogram for the luma plane
        var histogramInfo = MPSImageHistogramInfo(numberOfHistogramEntries: 256,
                                                  histogramForAlpha: false,
                                                  minPixelValue: vector_float4(0,0,0,0),
                                                  maxPixelValue: vector_float4(1,1,1,1))
        let histogram = MPSImageHistogram(device: device, histogramInfo: &histogramInfo)
        let histogramLength = histogram.histogramSize(forSourceFormat: yTexture.pixelFormat)
        guard let histogramBuffer = device.makeBuffer(length: histogramLength, options: [.storageModePrivate]) else {
            log.error("error creating image histogram buffer")
            return
        }
        
        histogram.encode(to: commandBuffer,
                         sourceTexture: yTexture,
                         histogram: histogramBuffer,
                         histogramOffset: 0)
                
        // create a result buffer for our gamma correction
        guard let gammaResult = device.makeBuffer(length: MemoryLayout<Float>.size, options: [.storageModeShared]) else {
            log.error("error creating gamme result buffer")
            return
        }
        
        // create a gamma compute encoder and pass it the histogram data
        guard let gammaEncoder = commandBuffer.makeComputeCommandEncoder() else {
            log.error("error creating gamma encoder")
            return
        }
        
        var targetBrightness = self.targetBrightness
        gammaEncoder.setComputePipelineState(calculateGammaCorrectionPipelineState)
        gammaEncoder.setBuffer(histogramBuffer, offset: 0, index: 0)
        gammaEncoder.setBytes(&histogramInfo.numberOfHistogramEntries, length: MemoryLayout<Int>.size, index: 1)
        gammaEncoder.setBytes(&targetBrightness, length: MemoryLayout<Float>.size, index: 2)
        gammaEncoder.setBuffer(gammaResult, offset: 0, index: 3)
        gammaEncoder.dispatchThreads(MTLSizeMake(1, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
        gammaEncoder.endEncoding()
        
        // execute histogram and gamma shaders
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        var gamma = gammaResult.contents().bindMemory(to: Float.self, capacity: 1).pointee
        guard gamma < 1.0 else {
            // image is bright enough
            return
        }
        
        // image is too dark, create a new command buffer for gamma correction
        commandBuffer = commandQueue.makeCommandBuffer()
        guard commandBuffer != nil else {
            log.error("error creating metal command buffer")
            return
        }

        // create a writable RGB texture
        let rgbTextureDesc = MTLTextureDescriptor()
        rgbTextureDesc.pixelFormat = .bgra8Unorm
        rgbTextureDesc.width = CVPixelBufferGetWidth(capturedImage)
        rgbTextureDesc.height = CVPixelBufferGetHeight(capturedImage)
        rgbTextureDesc.usage = [.shaderWrite, .shaderRead]
        guard let rgbTexture = device.makeTexture(descriptor: rgbTextureDesc) else {
            log.error("error creating RGB texture")
            return
        }
        
        // convert the Y + CbCr textures into RGB with applied gamma correction
        guard let convertYCbCrToRGBEncoder = commandBuffer.makeComputeCommandEncoder() else {
            log.error("error creating YCbCr to RGB encoder")
            return
        }
        convertYCbCrToRGBEncoder.setComputePipelineState(convertYCbCrToRGBPipelineState)
        convertYCbCrToRGBEncoder.setTexture(yTexture, index: 0)
        convertYCbCrToRGBEncoder.setTexture(cbcrTexture, index: 1)
        convertYCbCrToRGBEncoder.setTexture(rgbTexture, index: 2)
        convertYCbCrToRGBEncoder.setBytes(&gamma, length: MemoryLayout<Float>.size, index: 0)

        let threadsPerGrid = MTLSize(width: rgbTexture.width, height: rgbTexture.height, depth: 1)
        let threadExecutionWidth = convertYCbCrToRGBPipelineState.threadExecutionWidth
        let threadExecutionHeight = convertYCbCrToRGBPipelineState.maxTotalThreadsPerThreadgroup / threadExecutionWidth
        let threadsPerThreadgroup = MTLSizeMake(threadExecutionWidth, threadExecutionHeight, 1)

        convertYCbCrToRGBEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        convertYCbCrToRGBEncoder.endEncoding()
        
        // create a blit encoder to copy the pixel data from the gpu to a buffer
        guard let blitEncoder = commandBuffer.makeBlitCommandEncoder() else {
            log.error("error creating blit command encoder")
            return
        }
        let bytesPerRow = 4 * rgbTexture.width
        guard let blitDestinationBuffer = device.makeBuffer(length: bytesPerRow * rgbTexture.height, options: .storageModeShared) else {
            log.error("error creating blit command destination buffer")
            return
        }
        blitEncoder.copy(from: rgbTexture,
                         sourceSlice: 0,
                         sourceLevel: 0,
                         sourceOrigin: MTLOrigin.init(x: 0, y: 0, z: 0),
                         sourceSize: MTLSize.init(width: rgbTexture.width, height: rgbTexture.height, depth: 1),
                         to: blitDestinationBuffer,
                         destinationOffset: 0,
                         destinationBytesPerRow: bytesPerRow,
                         destinationBytesPerImage: blitDestinationBuffer.length)
        blitEncoder.endEncoding()
        
        // execute gamma and blit shaders
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        // create a pixel buffer for the enhanced image data
        var enhancedImage: CVPixelBuffer?
        CVPixelBufferCreateWithBytes(kCFAllocatorDefault,
                                     rgbTexture.width,
                                     rgbTexture.height,
                                     kCVPixelFormatType_32BGRA,
                                     blitDestinationBuffer.contents(),
                                     bytesPerRow,
                                     nil,
                                     nil,
                                     nil,
                                     &enhancedImage)
        
        if let enhancedImage = enhancedImage {
            // add the enhanced pixel buffer to the frame along with gamma
            frame.enhancedImage = enhancedImage
            frame.enhancedImageGamma = gamma
        }
    }
    
    private func getMetalTexture(from pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat, planeIndex: Int) -> MTLTexture? {
        // Expects `pixelBuffer` to be bi-planar YCbCr
        if (CVPixelBufferGetPlaneCount(pixelBuffer) < 2) {
            return nil
        }
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
        var cvMetalTexture: CVMetalTexture?
        let status = CVMetalTextureCacheCreateTextureFromImage(nil,
                                                               textureCache,
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
