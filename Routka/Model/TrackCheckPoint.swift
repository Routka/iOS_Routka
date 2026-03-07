//
//  TrackCheckPoint.swift
//  Routka
//
//  Created by vladukha on 19.02.2026.
//
import Foundation
import CoreLocation

/// A checkpoint used to determine if a track has passed a specific geographic point.
/// 
/// This struct represents a location-based checkpoint with a defined distance threshold.
/// It can check whether a given location is within the threshold and track if the checkpoint
/// has been passed.
nonisolated
struct TrackCheckPoint: Equatable {
    /// The unique identifier of the checkpoint.
    let id: UUID = .init()
    
    /// The associated track point representing the geographic position of the checkpoint.
    let point: TrackPoint
    
    /// Indicates whether the checkpoint has been passed.
    private(set) var checkPointPassed: Bool = false
    
    /// Initializes a checkpoint with the given track point and distance threshold.
    ///
    /// - Parameters:
    ///   - point: The track point representing the geographic location of the checkpoint.
    ///   - distanceThreshold: The distance threshold (in meters) to confirm the checkpoint passing.
    init(point: TrackPoint, distanceThreshold: CLLocationDistance) {
        self.distanceThreshold = distanceThreshold
        self.point = point
        self.checkpointLocation = CLLocation(latitude: point.position.latitude, longitude: point.position.longitude)
    }
    
    /// Checks if a given location is within the checkpoint’s distance threshold.
    ///
    /// - Parameters:
    ///   - location: The geographic location to check.
    ///   - printA: An optional flag (default is false). Not used in this implementation.
    /// - Returns: `true` if the location is within the threshold, otherwise `false`.
    nonisolated
    func isPointInCheckpoint(_ location: CLLocationCoordinate2D, printA: Bool = false) -> Bool {
        let receivedLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let distanceToCheckpoint = receivedLocation.distance(from: checkpointLocation)
        let passed = distanceToCheckpoint < distanceThreshold
        
        return passed
    }
    
    /// Sets the checkpoint’s passing status.
    ///
    /// - Parameter value: The new passing status to set.
    mutating func setCheckpointPassing(to value: Bool) {
        self.checkPointPassed = value
    }
    
    static func == (lhs: TrackCheckPoint, rhs: TrackCheckPoint) -> Bool {
        lhs.id == rhs.id && lhs.checkPointPassed == rhs.checkPointPassed
    }
    
    private let distanceThreshold: CLLocationDistance
    private let checkpointLocation: CLLocation
}
