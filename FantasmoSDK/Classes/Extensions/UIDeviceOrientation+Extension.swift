//
//  UIDeviceOrientation+Extension.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 21.04.2021.
//

import Foundation

extension UIDeviceOrientation: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .unknown: return "unknown"
        case .portrait: return "portrait"
        case .portraitUpsideDown: return "portraitUpsideDown"
        case .landscapeLeft: return "landscapeLeft"
        case .landscapeRight: return "landscapeRight"
        case .faceUp: return "faceUp"
        case .faceDown: return "faceDown"
        }
    }
    
}
