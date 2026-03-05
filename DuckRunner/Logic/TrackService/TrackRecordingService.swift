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
    /// Publishes the current active track or nil if there is no ongoing session.
    private(set) var currentTrack: Track? = nil
    private(set) var stopPolicy: RecordingAutoStopPolicy = .manual
    private(set) var stopPolicyProgress: Double = 0.0
    private(set) var isRecording: Bool = false
    
    /// Appends a new point to the current track if recording is active.
    /// returns a suggested action to stop or continue the recording based on provided autostop policy
    @discardableResult
    func appendTrackPosition(_ point: TrackPoint) throws(TrackServiceError) -> SuggestedRecordingAction {
        guard currentTrack != nil else {
            throw.noCurrentTrack
        }
        guard isRecording else {
            throw .currentTrackIsFinished
        }
        
        self.currentTrack?.points.append(point)
        
        switch self.stopPolicy.type {
        case .manual:
            return .allow
        case .reachingSpeed(let cLLocationSpeed):
            self.stopPolicyProgress = max(0, min(1, point.speed/cLLocationSpeed))
            if point.speed >= cLLocationSpeed {
                return .immediate
            } else {
                return .allow
            }
        case .reachingDistance(let cLLocationDistance):
            if let totalDistance = self.currentTrack?.points.totalDistance() {
                self.stopPolicyProgress = max(0, min(1, totalDistance/cLLocationDistance))
                if totalDistance >= cLLocationDistance {
                    return .immediate
                } else {
                    return .allow
                }
            } else {
                return .allow
            }
        }
    }
    
    /// Begins a new track recording session at the specified date.
    func startTrack(_ stopPolicy: RecordingAutoStopPolicy = .manual) {
        self.currentTrack = .init(points: [])
        self.stopPolicy = stopPolicy
        self.stopPolicyProgress = 0.0
        self.isRecording = true
        // Re-enable the idle timer after stopping the track
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    /// Stops the current track session at the specified date and marks it as finished.
    @discardableResult
    func stopTrack() throws(TrackServiceError) -> Track {
        // Re-enable the idle timer after stopping the track
        UIApplication.shared.isIdleTimerDisabled = false
        guard let currentTrack = currentTrack else {
            throw .noCurrentTrack
        }
        self.isRecording = false
        self.currentTrack = currentTrack
        return currentTrack
    }
    
    func clearTrack() {
        self.currentTrack = nil
        self.isRecording = false
    }
}
