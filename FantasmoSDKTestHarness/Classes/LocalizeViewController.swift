//
//  LocalizeViewController.swift
//  FantasmoSDKTestHarness
//
//  Created by Nick Jensen on 28.10.21.
//

import UIKit
import FantasmoSDK
import CoreLocation
import MapKit
import Network

class LocalizeViewController: UIViewController {

    enum Result {
        case location(_ location: FMLocationResult, date: Date)
        case error(_ error: FMError)
    }
    
    @IBOutlet var resultText: UITextView!
    @IBOutlet var scanQRCodeSwitch: UISwitch!
    @IBOutlet var isSimulationSwitch: UISwitch!
    @IBOutlet var showsStatisticsSwitch: UISwitch!
    @IBOutlet var testSpotButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

    var isCheckingAvailability: Bool = false
    var isConnectedToTheInternet: Bool = false
    var results: [Result] = []
    var currentLocation: CLLocation?
    let locationManager: CLLocationManager = CLLocationManager()
    let networkMonitor: NWPathMonitor = NWPathMonitor()
    var startDate: Date!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        title = "Localize"
                
        networkMonitor.start(queue: DispatchQueue.main)
        networkMonitor.pathUpdateHandler = { [weak self] path in
            self?.isConnectedToTheInternet = path.status == .satisfied
        }
        
        // Disable until the users location is determined
        testSpotButton.isEnabled = false
        activityIndicator.startAnimating()
        
        resultText.text = ""
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !PermissionsViewController.hasRequiredPermissions {
            performSegue(withIdentifier: "presentPermissionsViewController", sender: nil)
            return
        }
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    @IBAction func handleCheckSpotButton(_ button: UIButton) {
        guard !isCheckingAvailability else {
            return
        }
        guard isConnectedToTheInternet else {
            showAlert(title: "No internet connection.")
            return
        }
        var location: CLLocation
        if isSimulationSwitch.isOn {
            location = CLLocation(latitude: 52.50578283943285, longitude: 13.378954977173915)
        } else if let currentLocation = currentLocation {
            location = currentLocation
        } else {
            showAlert(title: "Device location unknown.")
            return
        }
        isCheckingAvailability = true
        activityIndicator.startAnimating()
        FMParkingViewController.isParkingAvailable(near: location) { [weak self] isParkingAvailable in
            self?.isCheckingAvailability = false
            self?.activityIndicator.stopAnimating()
            if !isParkingAvailable {
                self?.showAlert(title: "Unavailable", message: "There are no mapped spaces near this spot.")
                return
            }
            self?.results.removeAll()
            self?.mapViewController?.clearLocationResults()
            self?.startParkingFlow()
        }
    }
    
    @IBAction func handleSimulationModeSwitch(_ sender: UISwitch) {
        let newTitle = isSimulationSwitch.isOn ? "Localize (Simulated)" : "Localize"
        testSpotButton.setTitle(newTitle, for: .normal)
    }
    
    func startParkingFlow() {
        let sessionId = "FTH-\(UUID().uuidString)"
        let parkingViewController = FMParkingViewController(sessionId: sessionId)
        parkingViewController.delegate = self
        parkingViewController.isSimulation = isSimulationSwitch.isOn
        parkingViewController.showsStatistics = showsStatisticsSwitch.isOn
        if !scanQRCodeSwitch.isOn {
            parkingViewController.qrCodeDetector = MockQRCodeDetector()
        }
        parkingViewController.modalPresentationStyle = .fullScreen
        self.present(parkingViewController, animated: true) { [weak self] in
            self?.startDate = Date()
            self?.resultText.text = "Session: \(sessionId)\n"
        }
    }
    
    func appendResult(_ result: Result) {
        results.append(result)
        resultText.text += "\n"
        switch result {
        case .location(let locationResult, let date):
            resultText.text += "📍 Location \(numberOfLocationResults)\n"
            resultText.text += "Latitude: \(locationResult.location.coordinate.latitude)\n"
            resultText.text += "Longitude: \(locationResult.location.coordinate.longitude)\n"
            resultText.text += "Confidence: \(locationResult.confidence.description)\n"
            resultText.text += String(format: "Time: %.2fs\n", date.timeIntervalSince(startDate))
        case .error(let error):
            resultText.text += "💣 Error: \(error.debugDescription)\n"
        }
    }
}

extension LocalizeViewController: FMParkingViewControllerDelegate {
        
    func parkingViewController(_ parkingViewController: FMParkingViewController, didReceiveLocalizationResult result: FMLocationResult) {
        appendResult(.location(result, date: Date()))
        mapViewController?.addLocationResult(result)
        
        if Settings.localizeForever {
            return
        }
                
        if numberOfLocationResults < Settings.maxLocationResults, result.confidence < Settings.desiredResultConfidence {
            return
        }
        
        parkingViewController.dismiss(animated: true)
    }
    
    func parkingViewController(_ parkingViewController: FMParkingViewController, didReceiveLocalizationError error: FMError, errorMetadata: Any?) {
        appendResult(.error(error))
        
        if Settings.localizeForever {
            return
        }
                
        if numberOfErrorResults < Settings.maxErrorResults {
            return
        }
        
        parkingViewController.dismiss(animated: true)
    }
}

extension LocalizeViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, CLLocationCoordinate2DIsValid(location.coordinate) else {
            return
        }
        currentLocation = location
        testSpotButton.isEnabled = true
        activityIndicator.stopAnimating()
    }
}

extension LocalizeViewController {

    var numberOfLocationResults: Int {
        let locations = results.filter { result in
            if case .location(_, _) = result {
                return true
            }
            return false
        }
        return locations.count
    }
    
    var numberOfErrorResults: Int {
        let errors = results.filter { result in
            if case .error(_) = result {
                return true
            }
         
            return false
        }
        return errors.count
    }
    
    var mapViewController: MapViewController? {
        guard let tabBarController = self.tabBarController,
              let navigationController = tabBarController.viewControllers![1] as? UINavigationController,
              let mapViewController = navigationController.viewControllers.first as? MapViewController else {
            return nil
        }
        return mapViewController
    }
    
    @IBAction func dismissModal(unwindSegue: UIStoryboardSegue) {
        
    }
}
