//
//  TrackOverlayProtocol.swift
//  DuckRunner
//
//  Created by vladukha on 24.02.2026.
//

import CoreLocation
import MapKit

protocol TrackOverlayProtocol: MKOverlay, Equatable {
    var points: [MKMapPoint] { get }
}

