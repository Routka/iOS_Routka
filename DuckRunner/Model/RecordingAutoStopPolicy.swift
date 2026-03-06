//
//  RecordingAutoStopPolicy.swift
//  DuckRunner
//
//  Created by vladukha on 04.03.2026.
//
import Foundation
import CoreLocation

/// Condition to auto stop the track recording
struct RecordingAutoStopPolicy: Hashable {
    enum PolicyType: Equatable, Hashable {
        case manual
        case reachingSpeed(CLLocationSpeed)
        case reachingDistance(CLLocationDistance)
    }
    
    let name: String
    let type: PolicyType
    /// System name icon of a measuredType
    var image: String {
        switch type {
        case .manual:
            return "hand.tap"
        case .reachingSpeed(_):
            return "gauge.open.with.lines.needle.67percent.and.arrowtriangle"
        case .reachingDistance(_):
            return "lines.measurement.horizontal.aligned.bottom"
        }
    }
    
    static let manual: RecordingAutoStopPolicy = .init(name: "manual", type: .manual)
    
    static func reachingSpeed(_ speed: CLLocationSpeed, name: String) -> RecordingAutoStopPolicy {
        RecordingAutoStopPolicy(name: name, type: .reachingSpeed(speed))
    }
    
    static func reachingDistance(_ distance: CLLocationSpeed, name: String) -> RecordingAutoStopPolicy {
        RecordingAutoStopPolicy(name: name, type: .reachingDistance(distance))
    }
    
}
