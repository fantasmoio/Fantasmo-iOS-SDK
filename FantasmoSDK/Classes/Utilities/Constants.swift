//
//  Constants.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 29.07.2021.
//

import CoreGraphics

struct Constants {
    
    /// Compression factor of JPEG encoding, range 0.0 (worse) to 1.0 (best).
    /// Anything below 0.7 severely degrades localization recall and accuracy.
    static let jpegCompressionRatio: Float = 0.9
    
}
