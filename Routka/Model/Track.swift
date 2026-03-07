//
//  Track.swift
//  Routka
//
//  Created by vladukha on 15.02.2026.
//
import Foundation
import CoreLocation
import CoreData

/// A model representing a recorded track consisting of multiple location points and timing information.
/// 
/// This structure provides the identity, the sequence of track points, time boundaries, and metadata such as 
/// parent track reference and track type.
/// 
/// Use this model to manage and store track data captured during a route recording session.
struct Track: Codable, Hashable, Identifiable {
    /// Unique identifier for the track.
    let id: String
    
    /// The sequence of recorded location points that form this track.
    var points: [TrackPoint]
    
    /// The starting date and time of the track.
    var startDate: Date {
        return self.points.first?.date ?? .now
    }
    
    /// The end date and time of the track, if stopped.
    var stopDate: Date? {
        guard self.points.count > 1 else { return nil }
        return self.points.last?.date
    }
    
    /// Identifier of a parent track, if any.
    var parentID: String?
    
    /// The type of the track, which influences how the track is replayed or handled.
    var type: TrackType = .classical
    
    /// Changes the type of the track.
    ///
    /// - Parameter newType: The new track type to set.
    mutating func changeType(to newType: TrackType) {
        self.type = newType
    }
    
    /// Creates a new Track instance with specified id, points, and optional parentID.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the track. Defaults to a new UUID string.
    ///   - points: Array of TrackPoint objects that comprise the track. Defaults to empty.
    ///   - parentID: Identifier of a parent track if this track is related. Defaults to nil.
    init(id: String = UUID().uuidString,
         points: [TrackPoint] = [], parentID: String? = nil) {
        self.points = points
//        self.startDate = startDate
//        self.stopDate = stopDate
        self.id = id
        self.parentID = parentID
    }
}

/// A model for a single recorded location point on a track.
///
/// Includes geographic position, speed at the point, and the timestamp of the record to represent a snapshot 
/// of the track's progress at a given moment.
struct TrackPoint: Codable, Equatable, Hashable {
    /// The geographic coordinate for this track point.
    let position: CLLocationCoordinate2D
    
    /// The speed measured at this point.
    let speed: CLLocationSpeed
    
    /// The date and time this point was recorded.
    let date: Date
    
    /// Creates a new TrackPoint instance.
    ///
    /// - Parameters:
    ///   - position: Geographic coordinate of the track point.
    ///   - speed: Speed measured at the track point.
    ///   - date: Timestamp when the point was recorded.
    init(position: CLLocationCoordinate2D, speed: CLLocationSpeed, date: Date) {
        self.position = position
        self.speed = speed
        self.date = date
    }
}

