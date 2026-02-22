//
//  TrackControllerProtocol.swift
//  DuckRunner
//
//  Created by vladukha on 15.02.2026.
//
import Foundation

/// Protocol describing ViewModel to connect UI controlling the Track
protocol TrackControllerProtocol: ObservableObject {
    var currentTrack: Track? { get }
    func startTrack()
    func stopTrack() async throws
}
