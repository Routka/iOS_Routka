//
//  TrackType.swift
//  Routka
//
//  Created by vladukha on 22.02.2026.
//
import Foundation

/// Enum representing different track logic types, distinguishing how time and speed are recorded and handled in a track.
enum TrackType: String, Codable {
    /// Classical track: time recording starts with the driver stationary at the start; both time and driver start moving simultaneously.
    case classical
    /// Speedtrap track: started already at some speed, used to measure how fast a driver can pass a certain distance.
    case speedtrap
    
    /// Replay track: a replay of another track.
    case replay
}
