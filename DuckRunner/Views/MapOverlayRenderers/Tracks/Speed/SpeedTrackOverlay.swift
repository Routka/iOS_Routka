//
//  MapLine.swift
//  DuckRunner
//
//  Created by vladukha on 16.02.2026.
//
import MapKit
import SwiftUI

/// Bridge overlay to show line of a track on a map
final class SpeedTrackOverlay: NSObject, TrackOverlayProtocol {

    let points: [MKMapPoint]
    let speeds: [CLLocationSpeed]
    let boundingMapRect: MKMapRect

    var coordinate: CLLocationCoordinate2D {
        points.first?.coordinate ?? .init(latitude: 0, longitude: 0)
    }

    init(track: [TrackPoint]) {
        let sorted = track.sorted { $0.date < $1.date }

        self.points = sorted.map { MKMapPoint($0.position) }
        self.speeds = sorted.map { $0.speed }

        self.boundingMapRect =
            MKPolyline(points: points, count: points.count).boundingMapRect
    }
}


