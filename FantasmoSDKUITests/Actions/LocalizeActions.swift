//
//  LocalizeActions.swift
//  FantasmoSDKUITests
//
//  Created by Fantasmo QA on 28/4/2022.
//

import XCTest

enum LocalizeActions {
    static func toggle(_ toggle: LocalizeSwitch) {
        LocalizeElements.getSwitch(toggle).tapWhenHittable()
    }
    
    static func toggleQRCode() {
        LocalizeElements.getSwitch(LocalizeSwitch.qrCode).tapWhenHittable()
    }
    
    static func toggleDebugStats() {
        LocalizeElements.getSwitch(LocalizeSwitch.debugStats).tapWhenHittable()
    }
    
    static func toggleSimulationMode() {
        LocalizeElements.getSwitch(LocalizeSwitch.simulationMode).tapWhenHittable()
    }
    
    static func tapLocalizeButton() {
        LocalizeElements.localizeButton().tapWhenHittable()
    }
}
