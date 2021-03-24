//
//  CoreLocation+Extension.swift
//  FantasmoSDK
//
//  Created by Ryan on 10/1/20.
//

import CoreLocation

extension CLLocationManager : CLLocationManagerDelegate {
    
    private struct AssociatedKeys {
        static var delegateState: UInt8 = 0
    }
    
    public private(set) static var lastLocation: CLLocation?
    
    /**
     Intercept delegate method for execute delegate.
     
     - Parameter delegate: Delegate of CLLocation .
     */
    @objc func interceptedDelegate(delegate : Any) {
        objc_setAssociatedObject(self, &AssociatedKeys.delegateState, delegate, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        self.interceptedDelegate(delegate: self)
    }
    
    /**
     Swizzle method for exchange swizzled and original methods
     */
    static func swizzle() {
        let _: () = {
            let originalSelector = #selector(setter: CLLocationManager.delegate)
            let swizzledSelector = #selector(CLLocationManager.interceptedDelegate(delegate:))
            let originalMethod = class_getInstanceMethod(self, originalSelector)
            let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
            method_exchangeImplementations (originalMethod!, swizzledMethod!)
            log.debug()
        }()
    }
    
    /**
     invoked when new locations are available.  Required for delivery of deferred locations.

     @param manager Currnet location manager.
     @param locations An array of CLLocation objects in chronological order.
     */
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        CLLocationManager.lastLocation = locations.last
        guard let delegate = objc_getAssociatedObject(self, &AssociatedKeys.delegateState) as? CLLocationManagerDelegate else {
            log.warning("delegate not available")
            return
        }
        delegate.locationManager?(manager, didUpdateLocations: locations)
        log.debug()
    }
    
    /**
     invoked when new headings are available.  Required for delivery of deferred headings.
     
     @param manager Currnet location manager.
     @param heading CLHeading object with updated heading.
     */
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
        guard let delegate = objc_getAssociatedObject(self, &AssociatedKeys.delegateState) as? CLLocationManagerDelegate else {
            log.warning("delegate not available")
            return
        }
        delegate.locationManager?(manager, didUpdateHeading: heading)
        log.debug()
    }
    
    /**
     invoked when authorization status change.  Required to know status has been changed.
     
     @param manager Currnet location manager.
     @param status CLAuthorizationStatus object with updated status.
     */
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard let delegate = objc_getAssociatedObject(self, &AssociatedKeys.delegateState) as? CLLocationManagerDelegate else {
            log.warning("delegate not available")
            return
        }
        delegate.locationManager?(manager, didChangeAuthorization: status)
        log.debug()
    }
    
    /**
     invoked when authorization status change.  Required to know status has been changed.
     
     @param manager Currnet location manager.
     */
    @available(iOS 14.0, *)
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let delegate = objc_getAssociatedObject(self, &AssociatedKeys.delegateState) as? CLLocationManagerDelegate else {
            log.warning("delegate not available")
            return
        }
        delegate.locationManagerDidChangeAuthorization?(manager)
        log.debug()
    }
    
    /**
     Invoked when a new heading is available.
     
     @param manager Currnet location manager.
     Returns YES to display heading calibration info.
     */
    public func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        guard let delegate = objc_getAssociatedObject(self, &AssociatedKeys.delegateState) as? CLLocationManagerDelegate else {
            log.warning("delegate not available")
            return false
        }
        _ = delegate.locationManagerShouldDisplayHeadingCalibration?(manager)
        log.debug()
        return true
    }
    
    /**
     Invoked when there's a state transition for a monitored region or in response to a request for state.
     
     @param manager Currnet location manager.
     @param state The state of the specified region.
     @param region The region whose state was determined.
     */
    public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        guard let delegate = objc_getAssociatedObject(self, &AssociatedKeys.delegateState) as? CLLocationManagerDelegate else {
            log.warning("delegate not available")
            return
        }
        delegate.locationManager?(manager, didDetermineState: state, for: region)
        log.debug()
    }
    
    /**
     Invoked when a new set of beacons becomes available in the specified region or when a beacon goes out of range.
     
     @param manager Currnet location manager.
     @param beacons List of beacons which are in range.
     @param region The region object containing the parameters that were used to locate the beacons.
     */
    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        guard let delegate = objc_getAssociatedObject(self, &AssociatedKeys.delegateState) as? CLLocationManagerDelegate else {
            log.warning("delegate not available")
            return
        }
        delegate.locationManager?(manager, didRangeBeacons: beacons, in: region)
        log.debug()
    }
    
    /**
     Invoked when an error has occurred ranging beacons in a region. Error types are defined in "CLError.h".
     
     @param manager Currnet location manager.
     @param region The region object that encountered the error.
     @param error An error object containing the error code that indicates why ranging failed.
     */
    public func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        guard let delegate = objc_getAssociatedObject(self, &AssociatedKeys.delegateState) as? CLLocationManagerDelegate else {
            log.warning("delegate not available")
            return
        }
        delegate.locationManager?(manager, rangingBeaconsDidFailFor: region, withError: error)
        log.debug()
    }
    
    /**
     Invoked when beacon satisfying the constraint was detected.
     
     @param manager Currnet location manager.
     @param beacons List of beacons which are in range.
     @param beaconConstraint Constraint of beacon.
     */
    @available(iOS 13.0, *)
    public func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        guard let delegate = objc_getAssociatedObject(self, &AssociatedKeys.delegateState) as? CLLocationManagerDelegate else {
            log.warning("delegate not available")
            return
        }
        delegate.locationManager?(manager, didRange: beacons, satisfying: beaconConstraint)
        log.debug()
    }
    
    /**
     Invoked when no beacons were detected that satisfy the constraint.
     
     @param manager Currnet location manager.
     @param beaconConstraint Constraint of beacon.
     @param error Give reason for not detect beacons.
     */
    @available(iOS 13.0, *)
    public func locationManager(_ manager: CLLocationManager, didFailRangingFor beaconConstraint: CLBeaconIdentityConstraint, error: Error) {
        guard let delegate = objc_getAssociatedObject(self, &AssociatedKeys.delegateState) as? CLLocationManagerDelegate else {
            log.warning("delegate not available")
            return
        }
        delegate.locationManager?(manager, didFailRangingFor: beaconConstraint, error: error)
        log.debug()
    }
    
    /**
     Invoked when the user enters a monitored region.
     
     @param manager Currnet location manager.
     @param region An object containing information about the region that was entered.
     */
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let delegate = objc_getAssociatedObject(self, &AssociatedKeys.delegateState) as? CLLocationManagerDelegate else {
            log.warning("delegate not available")
            return
        }
        delegate.locationManager?(manager, didEnterRegion: region)
        log.debug()
    }
    
    /**
     Invoked when the user exits a monitored region.
     
     @param manager Currnet location manager.
     @param region An object containing information about the region that was exited
     */
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let delegate = objc_getAssociatedObject(self, &AssociatedKeys.delegateState) as? CLLocationManagerDelegate else {
            log.warning("delegate not available")
            return
        }
        delegate.locationManager?(manager, didExitRegion: region)
        log.debug()
    }
    
    /**
     Invoked when an error has occurred.
     
     @param manager Currnet location manager.
     @param error Give reason for failing location manager.
     */
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard let delegate = objc_getAssociatedObject(self, &AssociatedKeys.delegateState) as? CLLocationManagerDelegate else {
            log.warning("delegate not available")
            return
        }
        delegate.locationManager?(manager, didFailWithError: error)
        log.debug()
    }
    
    /**
     Invoked when a region monitoring error has occurred.
     
     @param manager Currnet location manager.
     @param region The region for which the error occurred.
     @param error An error object containing the error code that indicates why region monitoring failed.
     */
    public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        guard let delegate = objc_getAssociatedObject(self, &AssociatedKeys.delegateState) as? CLLocationManagerDelegate else {
            log.warning("delegate not available")
            return
        }
        delegate.locationManager?(manager, monitoringDidFailFor: region, withError: error)
        log.debug()
    }
    
    /**
     Invoked when a monitoring for a region started successfully.
     
     @param manager Currnet location manager.
     @param region The region that is being monitored.
     */
    public func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        guard let delegate = objc_getAssociatedObject(self, &AssociatedKeys.delegateState) as? CLLocationManagerDelegate else {
            log.warning("delegate not available")
            return
        }
        delegate.locationManager?(manager, didStartMonitoringFor: region)
        log.debug()
    }
    
    /**
     Invoked when location updates are automatically paused.
     
     @param manager Currnet location manager.
     */
    public func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        guard let delegate = objc_getAssociatedObject(self, &AssociatedKeys.delegateState) as? CLLocationManagerDelegate else {
            log.warning("delegate not available")
            return
        }
        delegate.locationManagerDidPauseLocationUpdates?(manager)
        log.debug()
    }
    
    /**
     Invoked when location updates are automatically resumed.
     
     @param manager Currnet location manager.
     */
    public func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        guard let delegate = objc_getAssociatedObject(self, &AssociatedKeys.delegateState) as? CLLocationManagerDelegate else {
            log.warning("delegate not available")
            return
        }
        delegate.locationManagerDidResumeLocationUpdates?(manager)
        log.debug()
    }
    
    /**
     Invoked when deferred updates will no longer be delivered.
     
     @param manager Currnet location manager.
     @param error An error will be returned if deferred updates end before the specified criteria are met.
     */
    public func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        guard let delegate = objc_getAssociatedObject(self, &AssociatedKeys.delegateState) as? CLLocationManagerDelegate else {
            log.warning("delegate not available")
            return
        }
        delegate.locationManager?(manager, didFinishDeferredUpdatesWithError: error)
        log.debug()
    }
    
    /**
     Invoked when the CLLocationManager determines that the device has visited a location, if visit monitoring is currently started
     
     @param manager Currnet location manager.
     @param visit The visit object that contains the information about the event.
     */
    public func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        guard let delegate = objc_getAssociatedObject(self, &AssociatedKeys.delegateState) as? CLLocationManagerDelegate else {
            log.warning("delegate not available")
            return
        }
        delegate.locationManager?(manager, didVisit: visit)
        log.debug()
    }
}
