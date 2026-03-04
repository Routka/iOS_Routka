//
//  TrackModelStorageConverters.swift
//  DuckRunner
//
//  Created by vladukha on 18.02.2026.
//

import Foundation
import CoreData
import CoreLocation

extension Track {
    /// Conversion initializer for building Track from a Core Data entity.
    init(_ track: TrackDTO) {
        let points: [TrackPoint] = track.points?.allObjects.compactMap({
            if let point = ($0 as? TrackPointDTO) {
                return TrackPoint(point)
            } else {
                return nil
            }
        }) ?? []
        self.points = points
            .sorted(by: {$0.date < $1.date})
        self.id = track.id ?? UUID().uuidString
        self.parentID = track.parentID
        if let type = track.type,
           let typeEnum = TrackType(rawValue: type) {
            self.type = typeEnum
        } else {
            self.type = .classical
        }
    }
}

extension TrackPointDTO {
    /// Conversion initializer for creating a Core Data TrackPointDTO from a TrackPoint.
    convenience init(context: NSManagedObjectContext,
                     _ trackPoint: TrackPoint) {
        self.init(context: context)
        self.latitude = trackPoint.position.latitude
        self.longitude = trackPoint.position.longitude
        self.speed = trackPoint.speed
        self.date = trackPoint.date
    }
}

extension TrackDTO {
    /// Conversion initializer for creating a Core Data TrackDTO from a Track.
    convenience init(context: NSManagedObjectContext,
                     _ track: Track) {
        self.init(context: context)
        self.id = track.id
        self.points = NSSet(array: track.points.map({TrackPointDTO(context: context, $0)}))
        self.parentID = track.parentID
        self.startDate = track.startDate
        self.type = track.type.rawValue
    }
}


extension TrackPoint {
    /// Conversion initializer for building TrackPoint from a Core Data entity.
    init(_ trackPoint: TrackPointDTO) {
        self.position = .init(latitude: trackPoint.latitude, longitude: trackPoint.longitude)
        self.speed = trackPoint.speed
        self.date = trackPoint.date ?? Date()
    }
}

extension MeasuredTrackDTO {
    /// Conversion initializer for creating a Core Data MeasuredTrackDTO from a MeasuredTrack.
    convenience init(context: NSManagedObjectContext,
                     _ track: MeasuredTrack) {
        self.init(context: context)
        self.id = track.id
        switch track.measurement.type {
        case .manual:
            self.type = "manual"
            self.value = 0.0
        case .reachingSpeed(let speed):
            self.type = "speed"
            self.value = speed
        case .reachingDistance(let distance):
            self.type = "distance"
            self.value = distance
        }
        self.name = track.measurement.name
        self.trackID = track.track.id
    }
}

extension MeasuredTrack {
    init(_ measuredDTO: MeasuredTrackDTO, _ trackDTO: TrackDTO) {
        switch measuredDTO.type {
        case "speed":
            self.measurement = .reachingSpeed(measuredDTO.value, name: measuredDTO.name ?? "Speed")
        case "distance":
            self.measurement = .reachingDistance(measuredDTO.value, name: measuredDTO.name ?? "Speed")
        default:
            self.measurement = .manual
        }
        self.track = .init(trackDTO)
        self.id = measuredDTO.id ?? UUID().uuidString
    }
}
