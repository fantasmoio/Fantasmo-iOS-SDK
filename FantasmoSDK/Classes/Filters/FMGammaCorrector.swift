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
    let gammaComputePipelineState: MTLComputePipelineState
    let textureCache: CVMetalTextureCache
    
    init?() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            log.error("error creating metal device")
            return nil
        }
        self.device = device
        
        guard let commandQueue = device.makeCommandQueue() else {
            log.error("error creating metal command queue")
            return nil
        }
        self.commandQueue = commandQueue
        
        do {
            let bundle = Bundle(for: type(of: self))
            self.library = try device.makeDefaultLibrary(bundle: bundle)
        } catch {
            log.error("error creating metal library: \(error.localizedDescription)")
            return nil
        }
        
        let gammaComputeFunctionName = "compute_gamma_correction"
        guard let gammaComputeFunction = library.makeFunction(name: gammaComputeFunctionName) else {
            log.error("unable to find compute shader: \(gammaComputeFunctionName)")
            return nil
        }
        
        do {
            self.gammaComputePipelineState = try device.makeComputePipelineState(function: gammaComputeFunction)
        } catch {
            log.error("error creating compute pipeline state: \(error.localizedDescription)")
            return nil
        }
        
        var textureCache: CVMetalTextureCache?
        let cvReturn = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
        guard cvReturn == kCVReturnSuccess, let textureCache = textureCache else {
            log.error("error creating cv metal texture cache - code \(cvReturn)")
            return nil
        }
        self.textureCache = textureCache
    }

    func process(frame originalFrame: FMFrame) -> FMFrame {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            log.error("error creating metal command buffer")
            return originalFrame
        }
        
        // texture containing just the Luma (Y) channel from the pixel buffer
        guard let yTexture = getMetalTexture(from: originalFrame.capturedImage, pixelFormat: .r8Unorm, planeIndex: 0) else {
            log.error("error creating metal texture from pixel buffer")
            return originalFrame
        }
        
        // calculate histogram for the source texture
        var numberOfBins: Int = 256
        var imageHistogramInfo = MPSImageHistogramInfo(numberOfHistogramEntries: numberOfBins,
                                                       histogramForAlpha: false,
                                                       minPixelValue: vector_float4(0,0,0,0),
                                                       maxPixelValue: vector_float4(1,1,1,1))
        
        let imageHistogram = MPSImageHistogram(device: device, histogramInfo: &imageHistogramInfo)
        let imageHistogramLength = imageHistogram.histogramSize(forSourceFormat: yTexture.pixelFormat)
        
        guard let imageHistogramBuffer = device.makeBuffer(length: imageHistogramLength, options: [.storageModePrivate]) else {
            log.error("error creating image histogram buffer")
            return originalFrame
        }
        
        imageHistogram.encode(to: commandBuffer,
                              sourceTexture: yTexture,
                              histogram: imageHistogramBuffer,
                              histogramOffset: 0)
        
        guard let gammaComputeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            log.error("error creating gamma compute encoder")
            return originalFrame
        }
        guard let gammaCorrectionResultBuffer = device.makeBuffer(length: MemoryLayout<Float>.size, options: [.storageModeShared]) else {
            log.error("error allocating gamme correction result buffer")
            return originalFrame
        }
                
        var targetBrightness: Float = 0.15
        gammaComputeEncoder.setComputePipelineState(gammaComputePipelineState)
        gammaComputeEncoder.setBuffer(imageHistogramBuffer, offset: 0, index: 0)
        gammaComputeEncoder.setBytes(&numberOfBins, length: MemoryLayout<Int>.size, index: 1)
        gammaComputeEncoder.setBytes(&targetBrightness, length: MemoryLayout<Float>.size, index: 2)
        gammaComputeEncoder.setBuffer(gammaCorrectionResultBuffer, offset: 0, index: 3)
        gammaComputeEncoder.dispatchThreads(MTLSizeMake(1, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
        gammaComputeEncoder.endEncoding()
            
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        let gamma = gammaCorrectionResultBuffer.contents().assumingMemoryBound(to: Float.self).pointee
        print("gammaCorrectionResult = \(gamma)")
        
        return originalFrame
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
