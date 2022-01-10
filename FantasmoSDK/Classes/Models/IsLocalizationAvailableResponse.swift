//
//  IsLocalizationAvailableResponse.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 05.01.22.
//

import Foundation

class IsLocalizationAvailableResponse: Codable {
    let available: Bool
    let reason: String?
}
