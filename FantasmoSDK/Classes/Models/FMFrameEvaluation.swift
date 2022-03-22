//
//  FMFrameEvaluation.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 21.02.22.
//

import Foundation

enum FMFrameEvaluationType: String {
    case imageQuality
}

struct FMFrameEvaluation: Encodable {
    let type: FMFrameEvaluationType
    let score: Float // 0.0 - 1.0
    let time: TimeInterval // time it took to perform the evaluation in seconds
    let userInfo: [String: String?]?  // optional analytics, errors etc.
    
    public enum CodingKeys: String, CodingKey {
        case type
        case score
        case imageQualityUserInfo
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(score, forKey: .score)
        switch type {
        case .imageQuality:
            try container.encode(userInfo, forKey: .imageQualityUserInfo)
        }
    }
}
