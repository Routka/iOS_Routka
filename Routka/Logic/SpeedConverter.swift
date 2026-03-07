//
//  SpeedConverter.swift
//  Routka
//
//  Created by vladukha on 15.02.2026.
//
import Foundation
import CoreLocation

/// A utility for converting speeds between different units (e.g., meters per second to kilometers per hour).
struct SpeedConverter {
    /// The speed value, stored as a measurement in meters per second.
    private let speed: Measurement<UnitSpeed>
    
    /// Initializes the converter with a speed value in meters per second.
    /// - Parameter speed: The speed value as a `CLLocationSpeed` (meters per second).
    init(speed: CLLocationSpeed) {
        self.speed = Measurement(value: speed, unit: UnitSpeed.metersPerSecond)
    }
    
    /// Returns the speed converted to the specified unit, rounded to the nearest integer.
    /// - Parameter speedMeasurement: The desired `UnitSpeed` to convert to.
    /// - Returns: The speed value converted to the specified unit, rounded to the nearest integer.
    func getSpeed(_ speedMeasurement: UnitSpeed) -> Int {
        let speedConverted = speed.converted(to: speedMeasurement)
        return Int(speedConverted.value.rounded())
    }
}

