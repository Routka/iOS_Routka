//
//  MeasuredTrackStorage.swift
//  DuckRunner
//
//  Created by vladukha on 04.03.2026.
//

import Foundation
import Combine

enum MeasuredTrackStorageAction {
    /// Indicates a track was created.
    case created(MeasuredTrack)
    /// Indicates a track was deleted.
    case deleted(MeasuredTrack)
    /// Indicates a track was updated.
    case updated(MeasuredTrack)
}

/// Abstraction for components that provide persistent storage and retrieval of tracks.
/// Defines CRUD methods and a publisher for storage action events.
protocol MeasuredTrackStorageProtocol {
    /// Publisher that notifies about storage actions performed on tracks.
    var actionPublisher: PassthroughSubject<MeasuredTrackStorageAction, Never> { get }
    func getMeasuredTracks() async -> [MeasuredTrack]
    func addMeasuredTrack(_ track: MeasuredTrack) async
    func deleteMeasuredTrack(_ track: MeasuredTrack) async
}
