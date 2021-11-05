//
//  FMQRCodeDetector.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 05.11.21.
//

import Foundation
import ARKit
import CoreImage

public protocol FMQRCodeDetector {
    var detectedQRCode: CIQRCodeFeature? { get set }
    func checkFrameAsyncThrottled(_ frame: ARFrame)
}
