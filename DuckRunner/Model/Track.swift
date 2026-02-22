//
//  Track.swift
//  DuckRunner
//
//  Created by vladukha on 15.02.2026.
//
import Foundation
import CoreLocation
import CoreData

/// Represents a recorded track consisting of multiple location points and timing information.
struct Track: Codable {
    /// Unique identifier for the track.
    let id: String
    /// The sequence of recorded location points that form this track.
    var points: [TrackPoint]
    /// The starting date and time of the track.
    let startDate: Date
    /// The end date and time of the track, if stopped.
    var stopDate: Date?
    /// id of a parent track
    var parentID: String?
    
    /// Type of a track, which results in determining way of replay logic
    var type: TrackType = .classical
    
    mutating func changeType(to newType: TrackType) {
        self.type = newType
    }
    
    /// Initializes a new Track with provided points and time range.
    init(id: String = UUID().uuidString,
         points: [TrackPoint] = [], startDate: Date, stopDate: Date? = nil, parentID: String? = nil) {
        self.points = points
        self.startDate = startDate
        self.stopDate = stopDate
        self.id = id
        self.parentID = parentID
    }
}

/// Represents a single recorded point on a track, including location, speed, and timestamp.
struct TrackPoint: Codable {
    /// The geographic coordinate for this track point.
    let position: CLLocationCoordinate2D
    /// The speed measured at this point.
    let speed: CLLocationSpeed
    /// The date and time this point was recorded.
    let date: Date
    /// Initializes a new TrackPoint with the given location, speed, and timestamp.
    init(position: CLLocationCoordinate2D, speed: CLLocationSpeed, date: Date) {
        self.position = position
        self.speed = speed
        self.date = date
    }
}



