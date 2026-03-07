//
//  DistanceConverter.swift
//  Routka
//
//  Created by vladukha on 15.02.2026.
//
import Foundation
import CoreLocation

/// A utility for converting distances between different units of measurement, such as meters, kilometers, miles, etc.
struct DistanceConverter {
    /// The distance value, stored as a measurement in meters.
    private let distance: Measurement<UnitLength>
    
    /// Initializes the converter with a distance in meters.
    ///
    /// - Parameter distance: The distance value in meters to be converted.
    init(distance: CLLocationDistance) {
        self.distance = Measurement(value: distance, unit: UnitLength.meters)
    }
    
    /// Converts and returns the distance to the specified unit of length.
    ///
    /// - Parameter lengthMeasurement: The desired unit of length to convert the distance to.
    /// - Returns: The distance value converted to the specified unit.
    func getDistance(_ lengthMeasurement: UnitLength) -> Double {
        let distanceConverted = distance.converted(to: lengthMeasurement)
        return distanceConverted.value
    }
}

