//
//  LocationService.swift
//  DuckRunner
//
//  Created by vladukha on 15.02.2026.
//
import Combine
import MapKit

let locationServiceLogger = MainLogger("LocationService")

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
        locationServiceLogger.log("Initialized", .info)
//        self.manageAuthorizationStatus(self.locationManager.authorizationStatus)
    }

    // Testing initializer for injecting a mock
    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
        super.init()
        self.locationManager.delegate = self
    }
    
    public func requestLocationAccess() {
        locationServiceLogger.log("Request Location Access has been envoked", .info)
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    private func manageAuthorizationStatus(_ status: CLAuthorizationStatus) {
        self.authorizationStatus.send(status)
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationServiceLogger.log("Location use is granted", .info)
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.startUpdatingLocation()
            self.locationManager.startUpdatingHeading()
        case .notDetermined:
            locationServiceLogger.log("User location service is not determined", .info)
            // Prompt for authorization again if needed
            
        case .restricted, .denied:
            locationServiceLogger.log("User location service is denied to restricted!", .warning)
            break
        @unknown default:
            locationServiceLogger.log("Unknown user authorization service status!", message: "Status: \(status)", .error)
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
        locationServiceLogger.log("Authorization has changed", .info)
        manageAuthorizationStatus(status)
    }
}
