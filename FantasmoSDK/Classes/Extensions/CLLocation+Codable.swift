//
//  CLLocation+Codable.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 09.12.21.
//

import Foundation
import CoreLocation

extension CLLocation: Encodable {

    public enum CodingKeys: String, CodingKey {
        case coordinate
        case altitude
        case horizontalAccuracy
        case verticalAccuracy
        case timestamp
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coordinate, forKey: .coordinate)
        try container.encode(altitude, forKey: .altitude)
        try container.encode(horizontalAccuracy, forKey: .horizontalAccuracy)
        try container.encode(verticalAccuracy, forKey: .verticalAccuracy)
        try container.encode(timestamp, forKey: .timestamp)
    }
}

extension CLLocationCoordinate2D: Encodable {
    
    public enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
}
