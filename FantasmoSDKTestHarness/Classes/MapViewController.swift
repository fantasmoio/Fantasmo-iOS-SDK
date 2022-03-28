//
//  MapViewController.swift
//  FantasmoSDKTestHarness
//
//  Created by Nick Jensen on 28.10.21.
//

import UIKit
import MapKit
import FantasmoSDK

class MapViewController: UIViewController {

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var locateUserButton: UIButton!
    @IBOutlet var showLocationResultsButton: UIButton!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet var sidebarView: UIView!
    @IBOutlet var sidebarViewTopConstraint: NSLayoutConstraint!
    
    var didLocateUser: Bool = false
    
    var locationResults: [FMLocationResult] = []
    var locationAnnotations: [MKPointAnnotation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locateUserButton.isEnabled = false
        showLocationResultsButton.isEnabled = false
        
        let pendingResults = locationResults
        locationResults.removeAll()
        if pendingResults.count > 0 {
            pendingResults.forEach { addLocationResult($0) }
            showLocationResults(animated: false)
        }
        
        sidebarView.layer.shadowColor = UIColor.black.cgColor
        sidebarView.layer.shadowOffset = .zero
        sidebarView.layer.shadowRadius = 4.0
        sidebarView.layer.shadowOpacity = 0.2
        sidebarView.clipsToBounds = false
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let sidebarViewTopPadding = 10.0
        sidebarViewTopConstraint.constant = view.safeAreaInsets.top - additionalSafeAreaInsets.top + sidebarViewTopPadding
        additionalSafeAreaInsets = .init(top: sidebarView.frame.height + 2.0 * sidebarViewTopPadding, left: 0, bottom: 0, right: 0)
    }
    
    @IBAction func handleLocateUserButton(_ sender: UIButton) {
        showUserLocation(animated: true)
    }

    @IBAction func handleShowLocationResultsButton(_ sender: UIButton) {
        showLocationResults(animated: true)
    }
    
    func addLocationResult(_ result: FMLocationResult) {
        locationResults.append(result)
        guard let _ = viewIfLoaded else {
            return
        }
        let newResultAnnotation = MKPointAnnotation()
        locationAnnotations.append(newResultAnnotation)
        newResultAnnotation.coordinate = result.location.coordinate
        newResultAnnotation.subtitle = "Location \(locationResults.count)\nConfidence: \(result.confidence)"
        mapView.addAnnotation(newResultAnnotation)
        showLocationResultsButton.isEnabled = true
        showLocationResults(animated: false)
    }
    
    func clearLocationResults() {
        guard let _ = viewIfLoaded else {
            locationResults.removeAll()
            return
        }
        mapView.removeAnnotations(locationAnnotations)
        locationResults.removeAll()
        showLocationResultsButton.isEnabled = false
    }
    
    private func showLocationResults(animated: Bool) {
        guard locationAnnotations.count > 0 else {
            return
        }
        mapView.showAnnotations(locationAnnotations, animated: animated)
    }
    
    private func showUserLocation(animated: Bool) {
        guard let userAnnotation = mapView.annotations.first(where: { $0 is MKUserLocation }) else {
            return
        }
        mapView.showAnnotations([userAnnotation], animated: animated)
    }
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let shouldShowUserLocation: Bool = !didLocateUser && locationResults.count == 0
        didLocateUser = true
        locateUserButton.isEnabled = true
        if shouldShowUserLocation {
            showUserLocation(animated: false)
        }
    }
}
