//
//  ARCamera.TrackingState.Reason+Extension.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 27.07.2021.
//

import ARKit

extension ARCamera.TrackingState.Reason: CaseIterable {
    public static var allCases: [ARCamera.TrackingState.Reason] {
        [.initializing, .relocalizing, .excessiveMotion, .insufficientFeatures]
    }
}
