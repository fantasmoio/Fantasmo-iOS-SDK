//
//  ImageQualityEstimationResult.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 11.11.21.
//

import Foundation

enum ImageQualityEstimationResult {
    case unknown
    case estimate(score: Float)
    case error(message: String)
}

extension ImageQualityEstimationResult: CustomStringConvertible {
    var description: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .estimate(let score):
            return "Estimate: \(score)"
        case .error(let message):
            return "Error: \(message)"
        }
    }
}
