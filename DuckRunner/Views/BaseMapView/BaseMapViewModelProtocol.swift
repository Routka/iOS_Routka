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
protocol BaseMapViewModelProtocol: ObservableObject, TrackControllerProtocol, LocationAccessViewModelProtocol {
    
    /// Checkpoint for starting the track replay
    var startReplayCheckpoint: TrackCheckPoint? { get }
    /// Final checkpoint for ending the track replay
    var stopReplayCheckpoint: TrackCheckPoint? { get }
    
    /// The currently active (or most recent) track, if any.
    var currentTrack: Track? { get set }
    
    /// Is TrackControl button available
    var isTrackControlAvailable: Bool { get }
    /// The currently being replayed track
    var replayTrack: Track? { get }
    /// Checkpoints to display
    var checkpoints: [TrackCheckPoint] { get }
    
    var mapMode: MapViewMode { get }
    
    /// The user's current measured speed, if available.
    var currentSpeed: CLLocationSpeed? { get set }
    
    var locationAccess: CLAuthorizationStatus { get }
    
    /// Begins a new track recording session.
    func startTrack()
    /// Ends the current track recording session, throwing if there is no active track.
    func stopTrack() async throws
    /// Remove selected track from replaying
    func deselectReplay()
    /// Try to request location authorization
    func requestLocation()
}

