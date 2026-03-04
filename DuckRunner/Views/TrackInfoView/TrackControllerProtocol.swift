//
//  TrackControllerProtocol.swift
//  DuckRunner
//
//  Created by vladukha on 15.02.2026.
//
import Foundation

/// Protocol describing ViewModel to connect UI controlling the Track
protocol TrackControllerProtocol: Observable {
    func isRecordingTrack() -> Bool
    func startTrack(_ mode: RecordingAutoStopPolicy)
    func stopTrack() async throws
}
