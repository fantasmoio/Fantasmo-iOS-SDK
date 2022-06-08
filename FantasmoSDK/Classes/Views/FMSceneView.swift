//
//  FMSceneView.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 02.06.22.
//

import UIKit
import ARKit
import CoreLocation

protocol FMSceneView: UIView {
    var delegate: FMSceneViewDelegate? { get set }
    func run()
    func pause()
    func startUpdatingLocation()
    func stopUpdatingLocation()
}

protocol FMSceneViewDelegate: AnyObject {
    func sceneView(_ sceneView: FMSceneView, didUpdate frame: FMFrame)
    func sceneView(_ sceneView: FMSceneView, didUpdate location: CLLocation)
    func sceneView(_ sceneView: FMSceneView, didFailWithError error: Error)
}
