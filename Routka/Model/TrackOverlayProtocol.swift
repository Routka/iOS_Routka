//
//  TrackOverlayProtocol.swift
//  Routka
//
//  Created by vladukha on 24.02.2026.
//

import CoreLocation
import MapKit

/// A protocol defining the requirements for visual overlays representing tracks on a map.
/// Conforming types must provide a collection of map points to depict the track visually.
protocol TrackOverlayProtocol: MKOverlay, Equatable {
    /// An array of `MKMapPoint` representing the points that make up the track overlay.
    var points: [MKMapPoint] { get }
}

