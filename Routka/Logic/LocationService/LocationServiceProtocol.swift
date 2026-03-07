//
//  LocationServiceProtocol.swift
//  Routka
//
//  Created by vladukha on 15.02.2026.
//
import Combine
import CoreLocation

/// A protocol that abstracts access to the device's location and its authorization status.
///
/// Conforming types provide a way to observe location updates and authorization changes,
/// and allow requesting location access from the user.
protocol LocationServiceProtocol {
    /// A publisher that emits updated `CLLocation` objects as the device's location changes.
    var location: PassthroughSubject<CLLocation, Never> { get }
    
    /// A current-value publisher that holds the current location authorization status.
    var authorizationStatus: CurrentValueSubject<CLAuthorizationStatus, Never> { get }
    
    /// Requests permission from the user to access the device's location.
    func requestLocationAccess()
}
