//
//  LocalizeTasks.swift
//  FantasmoSDKUITests
//
//  Created by Fantasmo QA on 28/4/2022.
//

struct ToggleLocalizeSwitches: Task {
    func perform() {
        LocalizeActions.toggleQRCode()
        LocalizeActions.toggleDebugStats()
        LocalizeActions.toggleSimulationMode()
    }
}

struct ToggleLocalizeSwitch: Task {
    let toggle: LocalizeSwitch
    
    init(_ toggle: LocalizeSwitch) {
        self.toggle = toggle
    }
    
    func perform() {
        LocalizeActions.toggle(toggle)
    }
    
    static func toggle(_ toggle: LocalizeSwitch) -> ToggleLocalizeSwitch {
        return ToggleLocalizeSwitch(toggle)
    }
}

struct StartLocalizing: Task {
    func perform() {
        LocalizeActions.tapLocalizeButton()
    }
}
