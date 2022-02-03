//
//  FMGammaCorrector.swift
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

class FMGammaCorrector {
    
    let device: MTLDevice
    let library: MTLLibrary
    let commandQueue: MTLCommandQueue
    let calculateGammaCorrectionPipelineState: MTLComputePipelineState
    let convertYCbCrToRGBPipelineState: MTLComputePipelineState
    let textureCache: CVMetalTextureCache
    
    init?() {
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

    func enhance(_ capturedImage: CVPixelBuffer) -> CVPixelBuffer? {
        let startDate = Date()
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            log.error("error creating metal command buffer")
            return nil
        }
        
        // create separate Y (Luma) and CbCr (Chroma) metal textures
        guard let yTexture = getMetalTexture(from: capturedImage, pixelFormat: .r8Unorm, planeIndex: 0),
              let cbcrTexture = getMetalTexture(from: capturedImage, pixelFormat: .rg8Unorm, planeIndex: 1)
        else {
            log.error("error creating YCbCr metal textures from pixel buffer")
            return nil
        }
        
        // calculate histogram for the Y texture
        var histogramInfo = MPSImageHistogramInfo(numberOfHistogramEntries: 256,
                                                  histogramForAlpha: false,
                                                  minPixelValue: vector_float4(0,0,0,0),
                                                  maxPixelValue: vector_float4(1,1,1,1))
        let histogram = MPSImageHistogram(device: device, histogramInfo: &histogramInfo)
        let histogramLength = histogram.histogramSize(forSourceFormat: yTexture.pixelFormat)
        
        guard let histogramBuffer = device.makeBuffer(length: histogramLength, options: [.storageModePrivate]) else {
            log.error("error creating image histogram buffer")
            return nil
        }
        
        histogram.encode(to: commandBuffer,
                         sourceTexture: yTexture,
                         histogram: histogramBuffer,
                         histogramOffset: 0)
        
        // calculate gamma correction using the histogram data
        guard let gammaCorrectionEncoder = commandBuffer.makeComputeCommandEncoder() else {
            log.error("error creating gamma correction encoder")
            return nil
        }
        
        // create a result buffer for our gamma correction
        guard let gammaCorrectionResult = device.makeBuffer(length: MemoryLayout<Float>.size, options: [.storageModeShared]) else {
            log.error("error allocating gamme correction result buffer")
            return nil
        }
        
        var targetBrightness: Float = 0.15
        gammaCorrectionEncoder.setComputePipelineState(calculateGammaCorrectionPipelineState)
        gammaCorrectionEncoder.setBuffer(histogramBuffer, offset: 0, index: 0)
        gammaCorrectionEncoder.setBytes(&histogramInfo.numberOfHistogramEntries, length: MemoryLayout<Int>.size, index: 1)
        gammaCorrectionEncoder.setBytes(&targetBrightness, length: MemoryLayout<Float>.size, index: 2)
        gammaCorrectionEncoder.setBuffer(gammaCorrectionResult, offset: 0, index: 3)
        gammaCorrectionEncoder.dispatchThreads(MTLSizeMake(1, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
        gammaCorrectionEncoder.endEncoding()
        
        // create a writable RGB texture
        let rgbTextureDesc = MTLTextureDescriptor()
        rgbTextureDesc.pixelFormat = .bgra8Unorm
        rgbTextureDesc.width = CVPixelBufferGetWidth(capturedImage)
        rgbTextureDesc.height = CVPixelBufferGetHeight(capturedImage)
        rgbTextureDesc.usage = [.shaderWrite]
        
        guard let rgbTexture = device.makeTexture(descriptor: rgbTextureDesc) else {
            log.error("error creating RGB texture")
            return nil
        }
        
        // convert the Y + CbCr textures into RGB and apply gamma correction
        guard let convertYCbCrToRGBEncoder = commandBuffer.makeComputeCommandEncoder() else {
            log.error("error creating YCbCr to RGB encoder")
            return nil
        }
        
        convertYCbCrToRGBEncoder.setComputePipelineState(convertYCbCrToRGBPipelineState)
        convertYCbCrToRGBEncoder.setTexture(yTexture, index: 0)
        convertYCbCrToRGBEncoder.setTexture(cbcrTexture, index: 1)
        convertYCbCrToRGBEncoder.setTexture(rgbTexture, index: 2)
        convertYCbCrToRGBEncoder.setBuffer(gammaCorrectionResult, offset: 0, index: 0)

        let threadsPerGrid = MTLSize(width: rgbTexture.width, height: rgbTexture.height, depth: 1)
        let threadExecutionWidth = convertYCbCrToRGBPipelineState.threadExecutionWidth
        let threadExecutionHeight = convertYCbCrToRGBPipelineState.maxTotalThreadsPerThreadgroup / threadExecutionWidth
        let threadsPerThreadgroup = MTLSizeMake(threadExecutionWidth, threadExecutionHeight, 1)

        convertYCbCrToRGBEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        convertYCbCrToRGBEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
                        
        let appliedGammaCorrection = gammaCorrectionResult.contents()
            .bindMemory(to: Float.self, capacity: 1).pointee
        
        // print("appliedGammaCorrection: \(appliedGammaCorrection)")
        
        print("time: \(Date().timeIntervalSince(startDate))")
        
        return nil
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

    /*
    var debugCaptureScope: MTLCaptureScope?
    
    func setUpDebugCaptureIfNeeded() {
        if #available(iOS 13.0, *) {
            if debugCaptureScope == nil {
                debugCaptureScope = MTLCaptureManager.shared().makeCaptureScope(device: device)
                debugCaptureScope?.label = "Gamma Corrector"
                guard let debugCaptureScope = debugCaptureScope else { return }
                let captureManager = MTLCaptureManager.shared()
                let captureDescriptor = MTLCaptureDescriptor()
                captureDescriptor.captureObject = debugCaptureScope
                do {
                    try captureManager.startCapture(with: captureDescriptor)
                }
                catch {
                    fatalError("error when trying to capture: \(error)")
                }
            }
        }
    }
    */
}
