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

    enum CodingKeys: String, CodingKey {
        case parkingInRadius
        case config
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        parkingInRadius = try container.decode(Bool.self, forKey: .parkingInRadius)
        do {
            config = try container.decodeIfPresent(RemoteConfig.Config.self, forKey: .config)
        } catch let jsonDecodeError {
            log.error("error decoding remote config - \(jsonDecodeError.localizedDescription)")
            config = nil
        }
    }
}
