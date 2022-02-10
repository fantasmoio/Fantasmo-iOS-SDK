//
//  MockARSession.swift
//  FantasmoSDKTests
//
//  Created by Nicholas Jensen on 07.02.22.
//

import Foundation
import AVFoundation
@testable import FantasmoSDK

class MockARSession {

    private let videoAssetReader: AVAssetReader
    private let videoTrackOutput: AVAssetReaderTrackOutput
    
    init(videoName: String, fileExtension: String = "mp4") {
        let bundle = Bundle(for: MockARSession.self)
        guard let videoPath = bundle.path(forResource: videoName, ofType: fileExtension)
        else {
            fatalError("video not found: \(videoName).\(fileExtension)")
        }
        let asset = AVURLAsset(url: URL(fileURLWithPath: videoPath))
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            fatalError("asset has no video tracks")
        }
        let videoOutputSettings = [
            String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
        ]
        videoTrackOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoOutputSettings)
        do {
            videoAssetReader = try AVAssetReader(asset: asset)
        } catch {
            fatalError("failed to create video asset reader: \(error.localizedDescription)")
        }
        videoAssetReader.add(videoTrackOutput)
        videoAssetReader.startReading()
    }
    
    func nextFrame() -> FMFrame? {
        while let sampleBuffer = videoTrackOutput.copyNextSampleBuffer() {
            let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer)
            if formatDesc?.mediaType == .video, let capturedImage = sampleBuffer.imageBuffer {
                return FMFrame(camera: MockCamera(), capturedImage: capturedImage)
            }
        }
        return nil
    }
}
