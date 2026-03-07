//
//  RecordingAutoStopPolicy.swift
//  Routka
//
//  Created by vladukha on 04.03.2026.
//
import Foundation
import CoreLocation

/// Model representing the condition used to automatically stop track recording.
struct RecordingAutoStopPolicy: Hashable {
    /// Represents the type of auto stop policy.
    enum PolicyType: Equatable, Hashable {
        case manual
        case reachingSpeed(CLLocationSpeed)
        case reachingDistance(CLLocationDistance)
    }
    
    /// The name of the auto stop policy.
    let name: String
    /// The type of the auto stop policy.
    let type: PolicyType
    /// System name icon of a measuredType.
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
    
    /// Manual auto stop policy.
    static let manual: RecordingAutoStopPolicy = .init(name: "manual", type: .manual)
    
    /// Creates an auto stop policy for reaching a certain speed.
    /// - Parameters:
    ///   - speed: The speed threshold to trigger auto stop.
    ///   - name: The name of this policy.
    /// - Returns: A new instance of `RecordingAutoStopPolicy` configured for speed-based stopping.
    static func reachingSpeed(_ speed: CLLocationSpeed, name: String) -> RecordingAutoStopPolicy {
        RecordingAutoStopPolicy(name: name, type: .reachingSpeed(speed))
    }
    
    /// Creates an auto stop policy for reaching a certain distance.
    /// - Parameters:
    ///   - distance: The distance threshold to trigger auto stop.
    ///   - name: The name of this policy.
    /// - Returns: A new instance of `RecordingAutoStopPolicy` configured for distance-based stopping.
    static func reachingDistance(_ distance: CLLocationSpeed, name: String) -> RecordingAutoStopPolicy {
        RecordingAutoStopPolicy(name: name, type: .reachingDistance(distance))
    }
    
}
