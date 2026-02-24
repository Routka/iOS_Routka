//
//  SpeedTrackOverlay 2.swift
//  DuckRunner
//
//  Created by vladukha on 20.02.2026.
//


import MapKit
import SwiftUI

/// Bridge overlay to show line of a track on a map
final class ReplayTrackOverlay: NSObject, TrackOverlayProtocol {

    let points: [MKMapPoint]
    let boundingMapRect: MKMapRect

    var coordinate: CLLocationCoordinate2D {
        points.first?.coordinate ?? .init(latitude: 0, longitude: 0)
    }

    init(track: [TrackPoint]) {
        let sorted = track.sorted { $0.date < $1.date }

        self.points = sorted.map { MKMapPoint($0.position) }

        self.boundingMapRect =
            MKPolyline(points: points, count: points.count).boundingMapRect
    }
}

