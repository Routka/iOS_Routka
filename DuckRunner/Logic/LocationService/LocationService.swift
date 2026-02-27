//
//  LocationService.swift
//  DuckRunner
//
//  Created by vladukha on 15.02.2026.
//
import Combine
import MapKit

final class LocationService: NSObject, CLLocationManagerDelegate, LocationServiceProtocol {
    public let location: PassthroughSubject<CLLocation, Never> = .init()
    // Publisher for authorization status changes
    public let authorizationStatus: CurrentValueSubject<CLAuthorizationStatus, Never> = .init(.notDetermined)
    private let locationManager: CLLocationManager

    // Main initializer for use in app
    override init() {
        self.locationManager = CLLocationManager()
        self.locationManager.distanceFilter = 8
        super.init()
        self.locationManager.delegate = self
//        self.manageAuthorizationStatus(self.locationManager.authorizationStatus)
    }

    // Testing initializer for injecting a mock
    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
        super.init()
        self.locationManager.delegate = self
    }
    
    public func requestLocationAccess() {
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    private func manageAuthorizationStatus(_ status: CLAuthorizationStatus) {
        self.authorizationStatus.send(status)
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("LOCATION: Location services authorized")
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.startUpdatingLocation()
            self.locationManager.startUpdatingHeading()
        case .notDetermined:
            print("LOCATION: not determined")
            // Prompt for authorization again if needed
            
        case .restricted, .denied:
            print("LOCATION: Denied or restricted")
            break
        @unknown default:
            break
        }
    }
    
    // MARK: - LocationManager Delegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.location.send(location)
        }
    }
    
    
    // Handle authorization status changes
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("LOCATION: didChangeAuthorization")
        manageAuthorizationStatus(status)
    }
}
