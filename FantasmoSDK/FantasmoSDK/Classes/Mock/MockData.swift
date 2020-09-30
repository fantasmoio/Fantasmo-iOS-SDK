//
//  MockData.swift
//  FantasmoSDK
//
//

import Foundation
import ARKit
import UIKit

open class MockData {
    
    public func getLocaliseResponseWithType(success: Bool) -> (params: [String : Any]?, image: Data?) {
        guard let jpegData = success ? UIImage(named: "inParking")?.toJpeg(compressionQuality: FMUtility.Constants.JpegCompressionRatio) :  UIImage(named: "onStreet")?.toJpeg(compressionQuality: FMUtility.Constants.JpegCompressionRatio) else {
            print("Error: Could not convert frame to JPEG.")
            return (nil, nil)
        }
        return ( self.getUserCordinates(isInParking: success), jpegData)
    }
    
    private func getUserCordinates(isInParking: Bool) -> [String : Any] {
        if isInParking {
            return [
                "intrinsics" : "{\"fx\": 1211.782470703125, \"fy\": 1211.9073486328125, \"cx\": 1017.4938354492188, \"cy\": 788.2992553710938}",
                "gravity"    : "{\"w\": 0.7729115057076497, \"x\": 0.026177782246603, \"y\": 0.6329531644390612, \"z\": -0.03595580186787759}",
                "capturedAt" :(NSDate().timeIntervalSince1970),
                "uuid" : "C6241E04-974A-4131-8B36-044A11E2C7F0",
                "coordinate": "{\"longitude\" : 11.572596873561112, \"latitude\": 48.12844364094412}"
            ] as [String : Any]
        }
        return [
            "intrinsics" : "{\"fx\": 1036.486083984375, \"fy\": 1036.486083984375, \"cx\": 480.23284912109375, \"cy\": 628.2947998046875}",
            "gravity"    : "{\"w\": 0.7634205318288221, \"x\": 0.05583266127506817, \"y\": 0.6407979294057553, \"z\": -0.058735161414937516}",
            "capturedAt" :(NSDate().timeIntervalSince1970),
            "uuid" : "A87E55CB-0649-4F87-A42F-8A33970F421E",
            "coordinate": "{\"longitude\" : 11.572596873561112, \"latitude\": 48.12844364094412}"
        ] as [String : Any]
    }
}
