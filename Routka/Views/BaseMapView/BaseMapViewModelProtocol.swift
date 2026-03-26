//
//  BaseMapViewModelProtocol.swift
//  Routka
//
//  Created by vladukha on 15.02.2026.
//
import Foundation
import SwiftUI
import MapKit

/// Protocol defining the required interface for map-based track recording view models.
/// Provides access to current track, position, speed, and track control actions.
protocol BaseMapViewModelProtocol: Observable, LocationAccessViewModelProtocol {
    var showStartPoint: Bool { get } //trackRecordingService.isRecording != true
    var showDeselectReplayButton: Bool { get } //replayValidator?.track != nil
    var showMeasuringProgress: Bool { get } //trackRecordingService.stopPolicy != .manual
    var showDismissRecordedTrackButton: Bool { get } //trackRecordingService.currentTrack != nil && trackRecordingService.isRecording == false
    var showControls: Bool { get } // trackControlMode != .hidden
    var showMeasureTrackSelectorButton: Bool { get } //isRecordingTrack() == false
    var recordingButtonIsRecording: Bool { get }
    
    var mapMode: MapViewMode { get }
    var trackControlMode: TrackControlMode { get }
    var currentSpeed: CLLocationSpeed? { get }
    var locationAccess: CLAuthorizationStatus { get }
    var trackRecordingService: any TrackRecordingServiceProtocol { get }
    var replayValidator: TrackReplayValidator? { get }
    /// Begins a new track recording session.
    func startTrack(_ mode: RecordingAutoStopPolicy)
    /// Ends the current track recording session, throwing if there is no active track.
    func stopTrack() async throws
    /// Remove selected track from replaying
    func deselectReplay()
    /// Try to request location authorization
    func requestLocation()
    /// Dismiss stats of already recorded track
    func dismissRecordedTrack()
}

