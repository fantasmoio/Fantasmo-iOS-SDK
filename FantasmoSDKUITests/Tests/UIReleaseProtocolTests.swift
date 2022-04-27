//
//  UIReleaseProtocolTests.swift
//  FantasmoSDKUITests
//
//  Created by Fantasmo QA on 28/4/2022.
//

import XCTest

class LocalizeTests: XCTestCase {
    let app = XCUIApplication()
    var alice: Actor!
    
    override func setUpWithError() throws {
        // stop the test suite on test failure
        continueAfterFailure = false
        
        alice = Actor(called: "Alice")
        app.launchArguments = ["UITesting"]
        app.launch()
        // grant app permissions if needed
        app.grantNeededPermissions()
    }
    
    override func tearDown() {
        // helps to clean up application state after failed tests, leave this here
        app.terminate()
    }

      // uncomment this to uninstall the application after the test suite finishes
//    override class func tearDown() {
//         XCUIApplication().uninstall()
//    }
    
    // test that we can toggle all toggles (switches) on and - wait for it - off!
    func testAllToggleStates() {
        // turn all switches on
        alice.attemptsTo(ToggleLocalizeSwitches())
        
        alice.sees(Localize.ToggleState(of: LocalizeSwitch.qrCode, is: SwitchState.On))
        alice.sees(Localize.ToggleState(of: LocalizeSwitch.debugStats, is: SwitchState.On))
        alice.sees(Localize.ToggleState(of: LocalizeSwitch.simulationMode, is: SwitchState.On))
        
        // turn all switches off
        alice.attemptsTo(ToggleLocalizeSwitches())
        
        alice.sees(Localize.ToggleState(of: LocalizeSwitch.qrCode, is: SwitchState.Off))
        alice.sees(Localize.ToggleState(of: LocalizeSwitch.debugStats, is: SwitchState.Off))
        alice.sees(Localize.ToggleState(of: LocalizeSwitch.simulationMode, is: SwitchState.Off))
    }
    
    // test simulation mode is working (targets dev environment)
    func testSimulationMode() {
        let sdkVersion = "Fantasmo SDK " + ProcessInfo.processInfo.environment["SDK_VERSION"]!
        
        // switch on simulation mode, debug toggle, and skip QR code
        alice.attemptsTo(ToggleLocalizeSwitches())
        
        // check localize button and toggle state are correct
        alice.sees(Localize.LocalizeButtonLabel(is: "Localize (Simulation)"))
        alice.sees(Localize.ToggleState(of: LocalizeSwitch.simulationMode, is: SwitchState.On))
       
        // begin localizing (hit localize button) and wait until SDK UI appears
        alice.attemptsTo(StartLocalizing())
        
        // wait for the localization session to properly begin
        alice.waitsUntil(DebugElements.textField(DebugTextField.sdkVersion), "isHittable", is: true, for: 10.0)
        alice.waitsUntil(DebugElements.textField(DebugTextField.localizationStatus), "label", is: "Status: localizing")
        
        // check the SDK version number is correct
        // this also tells us skipping QR code entry is working
        alice.sees(Debug.DebugContent(of: DebugTextField.sdkVersion, is: sdkVersion))
        
        // wait a while for localization session to finish, always waits the entire time for some reason
        alice.waitsUntil(LocalizeElements.localizeResults(), "isHittable", is: true, for: UITestTimeout.request)
        
        // check results have at least one entry with high confidence
        alice.sees(Localize.ResultsContain("Confidence: High"))
    }
    
    // MARK: need an AR session that doesn't have a QR code at the start for this to pass
    // manual QR code entry as well as flashlight toggle
    func testQRCodeFunctions() {
        let stopped = "Status: stopped"
        let localizing = "Status: localizing"
        
        // turn on simulation mode and debug stats
        alice.attemptsTo(ToggleLocalizeSwitch(LocalizeSwitch.simulationMode))
        alice.attemptsTo(ToggleLocalizeSwitch(LocalizeSwitch.debugStats))
        alice.attemptsTo(StartLocalizing())
        alice.waitsUntil(DebugElements.textField(DebugTextField.sdkVersion), "isHittable", is: true, for: 10.0)
        
        // toggle torch state on and then wait a second
        alice.attemptsTo(ToggleTorchState())
        // alice.sees(Debug.Torch(is: TorchState.On))

        // test localizing is stopped before manual QR code entry is done
        alice.sees(Debug.DebugContent(of: DebugTextField.localizationStatus, is: stopped))
        alice.attemptsTo(SubmitManualQRCode("qr-code"))
        
        // test localizing has begun after manual QR code entry is done
        alice.sees(Debug.DebugContent(of: DebugTextField.localizationStatus, is: localizing))
        
        // torch should automatically turn off after succesul QR code scan or entry
        alice.sees(Debug.Torch(is: TorchState.Off))
    }
}
