//
//  MeasuredTrack.swift
//  DuckRunner
//
//  Created by vladukha on 04.03.2026.
//

import Foundation

struct MeasuredTrack: Identifiable, Hashable {
    let id: String
    let measurement: RecordingAutoStopPolicy
    let track: Track
}
