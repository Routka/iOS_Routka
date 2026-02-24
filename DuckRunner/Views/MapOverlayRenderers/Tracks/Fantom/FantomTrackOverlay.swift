//
//  FantomTrackOverlay.swift
//  DuckRunner
//
//  Created by vladukha on 23.02.2026.
//


import MapKit
import SwiftUI

/// Bridge overlay to show line of a track for editing view, showing how original track looked like on a map
final class FantomTrackOverlay: NSObject, TrackOverlayProtocol {

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

