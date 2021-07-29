//
//  CGSize+Utils.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 29.07.2021.
//

import CoreGraphics

extension CGSize {
    init(width: Float, height: Float) {
        self.init(width: CGFloat(width), height: CGFloat(height))
    }
}
