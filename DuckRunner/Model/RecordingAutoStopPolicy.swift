//
//  RecordingAutoStopPolicy.swift
//  DuckRunner
//
//  Created by vladukha on 04.03.2026.
//
import Foundation
import CoreLocation

/// Condition to auto stop the track recording
struct RecordingAutoStopPolicy {
    enum PolicyType {
        case manual
        case reachingSpeed(CLLocationSpeed)
        case reachingDistance(CLLocationDistance)
    }
    
    let name: String
    let type: PolicyType
    
    static let manual: RecordingAutoStopPolicy = .init(name: "manual", type: .manual)
    
    static func reachingSpeed(_ speed: CLLocationSpeed, name: String) -> RecordingAutoStopPolicy {
        RecordingAutoStopPolicy(name: name, type: .reachingSpeed(speed))
    }
    
    static func reachingDistance(_ distance: CLLocationSpeed, name: String) -> RecordingAutoStopPolicy {
        RecordingAutoStopPolicy(name: name, type: .reachingDistance(distance))
    }
    
}
