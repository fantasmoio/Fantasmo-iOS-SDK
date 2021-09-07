//
//  FMFrame.swift
//  FantasmoSDK
//
//  Created by Sébastien Roger on 07.09.21.
//

import Foundation
import ARKit

public protocol FMFrame : AnyObject {
    var fmCamera : FMCamera { get }
    var capturedImage : CVPixelBuffer { get }
}
