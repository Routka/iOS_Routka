//
//  TrackCheckPoint.swift
//  DuckRunner
//
//  Created by vladukha on 19.02.2026.
//
import Foundation
import CoreLocation

/// Checkpoint which can be used to check if we passed it or not
nonisolated
struct TrackCheckPoint: Equatable {
    static func == (lhs: TrackCheckPoint, rhs: TrackCheckPoint) -> Bool {
        lhs.id == rhs.id && lhs.checkPointPassed == rhs.checkPointPassed
    }
    
    let id: UUID = .init()
    
    /// Distance threshold to confirm checkpoint passing
    private let distanceThreshold: CLLocationDistance
    private let checkpointLocation: CLLocation
    let point: TrackPoint
    
    private(set) var checkPointPassed: Bool = false
    
    init(point: TrackPoint, distanceThreshold: CLLocationDistance) {
        self.distanceThreshold = distanceThreshold
        self.point = point
        self.checkpointLocation = CLLocation(latitude: point.position.latitude, longitude: point.position.longitude)
    }
    
    nonisolated
    func isPointInCheckpoint(_ location: CLLocationCoordinate2D, printA: Bool = false) -> Bool {
        let receivedLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let distanceToCheckpoint = receivedLocation.distance(from: checkpointLocation)
        let passed = distanceToCheckpoint < distanceThreshold
        
        return passed
    }
    
    mutating func setCheckpointPassing(to value: Bool) {
        self.checkPointPassed = value
    }
    
}
