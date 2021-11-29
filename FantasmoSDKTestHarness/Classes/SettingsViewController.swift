//
//  SettingsViewController.swift
//  FantasmoSDKTestHarness
//
//  Created by Nick Jensen on 02.11.21.
//

import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet var localizeForeverSwitch: UISwitch!
    @IBOutlet var stopLocalizingSettingsViews: [UIView]!
    @IBOutlet var confidenceSegmentedControl: UISegmentedControl!
    @IBOutlet var locationsTextField: UITextField!
    @IBOutlet var errorsTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Settings"
        
        let localizeForever = Settings.localizeForever
        localizeForeverSwitch.isOn = localizeForever
        stopLocalizingSettingsViews.forEach {
            $0.isHidden = localizeForever
        }
        
        locationsTextField.text = String(Settings.maxLocationResults)
        errorsTextField.text = String(Settings.maxErrorResults)
                
        switch Settings.desiredResultConfidence {
        case .low:
            confidenceSegmentedControl.selectedSegmentIndex = 0
        case .medium:
            confidenceSegmentedControl.selectedSegmentIndex = 1
        case .high:
            confidenceSegmentedControl.selectedSegmentIndex = 2
        }
    }

    @IBAction func handleLocationsTextFieldChanged(_ sender: UITextField) {
        if let numberText = locationsTextField.text, let numberValue = Int(numberText) {
            Settings.maxLocationResults = numberValue
        } else {
            locationsTextField.text = String(Settings.maxLocationResults)
        }
    }
    
    @IBAction func handleErrorsTextFieldChanged(_ sender: UITextField) {
        if let numberText = errorsTextField.text, let numberValue = Int(numberText) {
            Settings.maxErrorResults = numberValue
        } else {
            errorsTextField.text = String(Settings.maxErrorResults)
        }
    }
    
    @IBAction func handleConfidenceSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        switch confidenceSegmentedControl.selectedSegmentIndex {
        case 0:
            Settings.setDesiredResultConfidence(.low)
        case 1:
            Settings.setDesiredResultConfidence(.medium)
        case 2:
            Settings.setDesiredResultConfidence(.high)
        default:
            break
        }
    }
    
    @IBAction func handleLocalizeForeverSwitch(_ sender: UISwitch) {
        let localizeForever = localizeForeverSwitch.isOn
        Settings.localizeForever = localizeForever
        stopLocalizingSettingsViews.forEach {
            $0.isHidden = localizeForever
        }
    }
}
