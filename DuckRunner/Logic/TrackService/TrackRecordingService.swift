//
//  TrackServiceSerivce.swift
//  DuckRunner
//
//  Created by vladukha on 15.02.2026.
//
import Combine
import Foundation
import UIKit.UIApplication

/// Service that manages the in-memory state and mutation of a live track during a session.
/// Provides methods for starting, stopping, and updating a track as the user moves.
@Observable
final class TrackRecordingService: TrackRecordingServiceProtocol {
    func clearTrack() {
        self.currentTrack = nil
    }
    
    /// Publishes the current active track or nil if there is no ongoing session.
    var currentTrack: Track? = nil
  
    
    /// Appends a new point to the current track if recording is active.
    func appendTrackPosition(_ point: TrackPoint) throws(TrackServiceError) {
        guard currentTrack != nil else {
            throw.noCurrentTrack
        }
        guard currentTrack?.stopDate == nil else {
            throw .currentTrackIsFinished
        }
        
        self.currentTrack?.points.append(point)
    }
    
    /// Begins a new track recording session at the specified date.
    func startTrack(at date: Date) {
        self.currentTrack = .init(points: [], startDate: date)
        // Re-enable the idle timer after stopping the track
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    /// Stops the current track session at the specified date and marks it as finished.
    @discardableResult
    func stopTrack(at date: Date) throws(TrackServiceError) -> Track {
        // Re-enable the idle timer after stopping the track
        UIApplication.shared.isIdleTimerDisabled = false
        guard var currentTrack = currentTrack else {
            throw .noCurrentTrack
        }
        currentTrack.stopDate = date
        self.currentTrack = currentTrack
        return currentTrack
    }
    
    
}
