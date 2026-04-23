//
//  TrackPoint Helpers.swift
//  Routka
//
//  Created by vladukha on 18.02.2026.
//
import CoreLocation
import Foundation

extension Array where Element == TrackPoint {
    /// Convenience extensions for arrays of TrackPoint, providing total distance and top speed calculation.
    
    /// Calculates the total distance covered by the sequence of track points, in meters.
    func totalDistance() -> CLLocationDistance {
        guard self.count > 1 else {
            return 0.0
        }

        var totalDistance: CLLocationDistance = 0.0
        
        for i in 0..<(self.count - 1) {
            let coordinate1 = self[i]
            let coordinate2 = self[i+1]
            
            // Convert CLLocationCoordinate2D to CLLocation to use the distance(from:) method
            let location1 = CLLocation(latitude: coordinate1.position.latitude,
                                       longitude: coordinate1.position.longitude)
            let location2 = CLLocation(latitude: coordinate2.position.latitude,
                                       longitude: coordinate2.position.longitude)
            
            totalDistance += location1.distance(from: location2)
        }
        
        return totalDistance
    }
    
    /// Finds the highest recorded speed among all track points in the array.
    nonisolated
    func topSpeedPoint() -> Self.Element? {
        let topSpeed = self
            .max { ls, rs in
                ls.speed < rs.speed
            }
        return topSpeed
    }
    
    func topSpeed() -> CLLocationSpeed? {
        self.topSpeedPoint()?.speed
    }
}
