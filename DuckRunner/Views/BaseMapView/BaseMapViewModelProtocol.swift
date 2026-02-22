//
//  BaseMapViewModelProtocol.swift
//  DuckRunner
//
//  Created by vladukha on 15.02.2026.
//
import Foundation
import SwiftUI
import MapKit

/// Protocol defining the required interface for map-based track recording view models.
/// Provides access to current track, position, speed, and track control actions.
protocol BaseMapViewModelProtocol: ObservableObject, TrackControllerProtocol {
    /// The currently active (or most recent) track, if any.
    var currentTrack: Track? { get set }
    
    /// Is TrackControl button available
    var isTrackControlAvailable: Bool { get }
    /// The currently being replayed track
    var replayTrack: Track? { get }
    /// Checkpoints to display
    var checkpoints: [TrackCheckPoint] { get }
    
    var mapMode: TrackingMapView.MapViewMode { get }
    
    /// The user's current measured speed, if available.
    var currentSpeed: CLLocationSpeed? { get set }
    /// Begins a new track recording session.
    func startTrack()
    /// Ends the current track recording session, throwing if there is no active track.
    func stopTrack() async throws
}

