//
//  MeasuredTrack.swift
//  Routka
//
//  Created by vladukha on 04.03.2026.
//

import Foundation

/// A model that combines a measurement policy and a recorded track.
/// 
/// This struct encapsulates the relationship between a measurement policy
/// used for recording and the actual track recorded according to that policy.
struct MeasuredTrack: Identifiable, Hashable {
    /// The unique identifier of the measured track.
    let id: String

    /// The measurement policy applied during recording.
    let measurement: RecordingAutoStopPolicy

    /// The recorded track associated with the measurement.
    let track: Track
}
