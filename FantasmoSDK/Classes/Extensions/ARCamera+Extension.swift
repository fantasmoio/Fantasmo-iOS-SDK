//
//  ARCamera+Extension.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 23.07.2021.
//

import ARKit

extension ARCamera {
    var pitch: Float { eulerAngles.x }
    var yaw: Float { eulerAngles.y }
    var roll: Float { eulerAngles.z }
}

