//
//  InitializeResponse.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 23.11.21.
//

import Foundation

struct InitializeResponse: Codable {
    let parkingInRadius: Bool
    let config: RemoteConfig.Config?
}
