//
//  TrackType.swift
//  DuckRunner
//
//  Created by vladukha on 22.02.2026.
//
import Foundation

enum TrackType: String, Codable {
    /// Classical Track, time recording starts with driver being stationary at the start and both time and driver start moving at the same time
    case classical
    /// Speeedtrap track, which is a track started already at some speed and used to measure how fast some distance a driver can pass
    case speedtrap
}
