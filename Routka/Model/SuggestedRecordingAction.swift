//
//  SuggestedRecordingAction.swift
//  Routka
//
//  Created by vladukha on 04.03.2026.
//

import Foundation

/// Represents the result or recommendation from a track recording operation.
/// Indicates whether recording should be allowed, forbidden, or started immediately.
enum SuggestedRecordingAction {
    /// Recording is allowed.
    case allow
    /// Recording is forbidden.
    case forbid
    /// Recording should start immediately.
    case immediate
}
