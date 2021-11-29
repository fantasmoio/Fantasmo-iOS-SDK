//
//  PermissionsViewController.swift
//  Fantasmo-Spot-Tester
//
//  Created by Nick Jensen on 28.10.21.
//

import Foundation
import UIKit
import CoreLocation
import AVFoundation

class PermissionsViewController: UIViewController {
        
    private var locationManager = CLLocationManager()
    
    @IBOutlet var locationPermissionButton: UIButton!
    @IBOutlet var locationPermissionNotDeterminedImage: UIImageView!
    @IBOutlet var locationPermissionAuthorizedImage: UIImageView!
    @IBOutlet var locationPermissionDeniedImage: UIImageView!

    @IBOutlet var cameraPermissionButton: UIButton!
    @IBOutlet var cameraPermissionNotDeterminedImage: UIImageView!
    @IBOutlet var cameraPermissionAuthorizedImage: UIImageView!
    @IBOutlet var cameraPermissionDeniedImage: UIImageView!
    
    @IBOutlet var continueButton: UIButton!
    
    static var hasRequiredPermissions: Bool {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let locationAuthorizationStatus = CLLocationManager().authorizationStatus
        return cameraAuthorizationStatus == .authorized &&
            (locationAuthorizationStatus == .authorizedAlways ||  locationAuthorizationStatus == .authorizedWhenInUse)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        updateButtonsAndImages()
    }
    
    private func updateButtonsAndImages() {
        let locationAuthorizationStatus = CLLocationManager().authorizationStatus
        let isLocationNotDetermined = locationAuthorizationStatus == .notDetermined
        let isLocationAuthorized = (locationAuthorizationStatus == .authorizedWhenInUse || locationAuthorizationStatus == .authorizedAlways)
        let isLocationDenied = (!isLocationNotDetermined && !isLocationAuthorized)
        locationPermissionNotDeterminedImage.isHidden = !isLocationNotDetermined
        locationPermissionAuthorizedImage.isHidden = !isLocationAuthorized
        locationPermissionDeniedImage.isHidden = !isLocationDenied
        locationPermissionButton.isEnabled = !isLocationAuthorized
        
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let isCameraPermissionNotDetermined = cameraAuthorizationStatus == .notDetermined
        let isCameraPermissionAuthorized = cameraAuthorizationStatus == .authorized
        let isCameraPermissionDenied = (!isCameraPermissionNotDetermined && !isCameraPermissionAuthorized)
        cameraPermissionNotDeterminedImage.isHidden = !isCameraPermissionNotDetermined
        cameraPermissionAuthorizedImage.isHidden = !isCameraPermissionAuthorized
        cameraPermissionDeniedImage.isHidden = !isCameraPermissionDenied
        cameraPermissionButton.isEnabled = !isCameraPermissionAuthorized
        
        continueButton.isEnabled = (isCameraPermissionAuthorized && isLocationAuthorized)
    }

    @IBAction func handleAuthorizeLocationButton(_ sender: UIButton) {
        let locationAuthorizationStatus = locationManager.authorizationStatus
        if locationAuthorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if locationAuthorizationStatus != .authorizedWhenInUse && locationAuthorizationStatus != .authorizedAlways {
            showOpenSettingsAlert(title: "No Location Access", message: "Access to your Location is unavailable. Please enable it in Settings.")
        }
    }
    
    
    @IBAction func handleAuthorizeCameraButton(_ sender: UIButton) {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if cameraAuthorizationStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateButtonsAndImages()
                }
            }
        } else if cameraAuthorizationStatus != .authorized {
            showOpenSettingsAlert(title: "No Camera Access", message: "Access to your Camera is unavailable. Please enable it in Settings.")
        }
    }
    
    @IBAction func handleContinueButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension PermissionsViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateButtonsAndImages()
    }
}
