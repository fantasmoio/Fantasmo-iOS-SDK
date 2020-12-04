//
//  LocalizeResponse.swift
//  FantasmoSDK
//

import Foundation

// MARK: - LocalizeResponse
class LocalizeResponse: Codable {
    let geofences: [Geofence]?
    let location: Location?
    let pose: Pose?
    let uuid: String?
}
