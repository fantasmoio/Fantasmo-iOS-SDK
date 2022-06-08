//
//  FMSimulationView.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 02.06.22.
//

import UIKit
import ARKit
import AVFoundation

class FMSimulationView: UIView, FMSceneView {
    
    weak var delegate: FMSceneViewDelegate?
    
    var sendsLocationUpdates: Bool = true
    
    let player: AVPlayer
    let playerLayer: AVPlayerLayer
    let videoOutput: AVPlayerItemVideoOutput
    let metadataOutput: AVPlayerItemMetadataOutput
    let jsonDecoder: JSONDecoder
    
    init(asset: AVAsset) {
        let videoOutputPixelBufferAttributes: [String: Any] = [
            kCVPixelBufferWidthKey as String: 1280,
            kCVPixelBufferHeightKey as String: 720,
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: videoOutputPixelBufferAttributes)
        metadataOutput = AVPlayerItemMetadataOutput(identifiers: nil)
        
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.add(videoOutput)
        playerItem.add(metadataOutput)

        player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.transform = CATransform3DMakeRotation(.pi / 2.0, 0, 0, 1.0)
        
        jsonDecoder = JSONDecoder()
        
        super.init(frame: .zero)
        
        metadataOutput.setDelegate(self, queue: .main)
        layer.addSublayer(playerLayer)
        backgroundColor = .black
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        playerLayer.frame = bounds
    }
    
    func run() {
        player.play()
    }
    
    func pause() {
        player.pause()
    }
    
    func startUpdatingLocation() {
        sendsLocationUpdates = true
    }
    
    func stopUpdatingLocation() {
        sendsLocationUpdates = false
    }
}

extension FMSimulationView: AVPlayerItemMetadataOutputPushDelegate {
    
    func metadataOutput(_ output: AVPlayerItemMetadataOutput, didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup], from track: AVPlayerItemTrack?) {
        guard let item = groups.first?.items.first,
              let itemValue = item.value(forKeyPath: #keyPath(AVMetadataItem.value)) as? String,
              let itemData = itemValue.data(using: .utf8) else
        {
            log.error("invalid metadata")
            return
        }
        
        guard videoOutput.hasNewPixelBuffer(forItemTime: item.time), let capturedImage = videoOutput.copyPixelBuffer(forItemTime: item.time, itemTimeForDisplay: nil) else {
            log.error("no pixel buffer for itemTime: \(item.time)")
            return
        }
        
        do {
            // simulate AR frame update
            let decodedData = try jsonDecoder.decode(FMSimulationFrame.self, from: itemData)
            let frame = FMFrame(camera: decodedData.camera, capturedImage: capturedImage, timestamp: Date().timeIntervalSince1970)
            delegate?.sceneView(self, didUpdate: frame)

            if sendsLocationUpdates {
                // simulate location update
                let location = decodedData.location
                let clLocation = CLLocation(
                    coordinate: location.coordinate,
                    altitude: location.altitude,
                    horizontalAccuracy: location.horizontalAccuracy,
                    verticalAccuracy: location.verticalAccuracy,
                    timestamp: Date()
                )
                delegate?.sceneView(self, didUpdate: clLocation)
            }

        } catch {
            var errorMessage = "error decoding metadata\n"
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .typeMismatch(let key, let value):
                    errorMessage += "typeMismatch - key: \(key), value: \(value)"
                case .valueNotFound(let key, let value):
                    errorMessage += "valueNotFound - key: \(key), value: \(value)"
                case .keyNotFound(let key, let value):
                    errorMessage += "keyNotFound - key: \(key), value: \(value)"
                case .dataCorrupted(let key):
                    errorMessage += "dataCorrupted - key: \(key)"
                default:
                    errorMessage += error.localizedDescription
                }
            }
            log.error(errorMessage, parameters: ["itemValue": itemValue])
        }
    }
}

