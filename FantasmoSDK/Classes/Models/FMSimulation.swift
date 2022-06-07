//
//  FMSimulation.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 07.06.22.
//

import Foundation
import AVFoundation
import CoreLocation

public class FMSimulation {
    
    /// Video asset recorded with the Fantasmo AR Recorder app.
    public let asset: AVAsset
    
    /// Actual location where the simulation was recorded. This is added to the video by the Fantasmo AR Recorder app.
    public let location: CLLocation
    
    public init(named videoName: String) {
        // Create an AVAsset
        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mov") else {
            fatalError("simulation '\(videoName).mov' not found")
        }
        self.asset = AVAsset(url: url)
        // Attempt to parse the location from the asset metadata
        let locationMetadata = asset.commonMetadata.first { $0.commonKey == AVMetadataKey.commonKeyLocation }
        let locationStringValue = locationMetadata?.stringValue
        let locationData = locationStringValue?.data(using: .utf8)
        guard let locationData = locationData, let simulatedLocation = try? JSONDecoder().decode(FMSimulationLocation.self, from: locationData) else {
            fatalError("error reading location from simulation '\(videoName).mov'")
        }
        self.location = CLLocation(
            coordinate: simulatedLocation.coordinate,
            altitude: simulatedLocation.altitude,
            horizontalAccuracy: simulatedLocation.horizontalAccuracy,
            verticalAccuracy: simulatedLocation.verticalAccuracy,
            timestamp: Date(timeIntervalSince1970: simulatedLocation.timestamp)
        )
    }
}
