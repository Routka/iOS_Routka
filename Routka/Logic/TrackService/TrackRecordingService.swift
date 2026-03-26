//
//  TrackServiceSerivce.swift
//  Routka
//
//  Created by vladukha on 15.02.2026.
//
import Combine
import Foundation
import UIKit.UIApplication

/// A service responsible for managing in-memory track recording sessions.
/// This service handles the state and mutation of a live track as the user moves,
/// including starting, stopping, and updating the track with new position points.
/// It also manages recording policies and progress related to automatic stopping conditions.
@Observable
final class TrackRecordingService: TrackRecordingServiceProtocol {
    /// The currently active track being recorded, or `nil` if no recording session is active.
    private(set) var currentTrack: Track? = nil
    
    /// The auto-stop policy that controls when recording should automatically stop.
    private(set) var stopPolicy: RecordingAutoStopPolicy = .manual
    
    /// The progress towards fulfilling the current stop policy condition,
    /// represented as a value from 0.0 to 1.0.
    private(set) var stopPolicyProgress: Double = 0.0
    
    /// Indicates whether a track recording session is currently active.
    private(set) var isRecording: Bool = false
    
    /**
     Appends a new position point to the current track if recording is active.
     
     - Parameter point: The new `TrackPoint` to append to the current track.
     - Throws: `TrackServiceError.noCurrentTrack` if there is no active track.
               `TrackServiceError.currentTrackIsFinished` if recording is not active.
     - Returns: A `SuggestedRecordingAction` indicating whether to continue or stop recording
                based on the provided auto-stop policy.
     */
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
    
    /**
     Starts a new track recording session using the specified auto-stop policy.
     
     - Parameter stopPolicy: The policy to determine when recording should automatically stop.
                             Defaults to `.manual`.
     */
    func startTrack(_ stopPolicy: RecordingAutoStopPolicy = .manual) {
        self.currentTrack = .init(points: [])
        self.stopPolicy = stopPolicy
        self.stopPolicyProgress = 0.0
        self.isRecording = true
        // Re-enable the idle timer after stopping the track
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    /**
     Stops the current track recording session and marks the track as finished.
     
     - Throws: `TrackServiceError.noCurrentTrack` if there is no active track.
     - Returns: The finished `Track`.
     */
    @discardableResult
    func stopTrack() throws(TrackServiceError) -> Track {
        // Re-enable the idle timer after stopping the track
        UIApplication.shared.isIdleTimerDisabled = false
        guard let currentTrack = currentTrack else {
            throw .noCurrentTrack
        }
        self.isRecording = false
        return currentTrack
    }
    
    /// Clears the current track and resets the recording state and stop policy to default.
    func clearTrack() {
        self.currentTrack = nil
        self.isRecording = false
        self.stopPolicy = .manual
        self.stopPolicyProgress = 0.0
    }
}
