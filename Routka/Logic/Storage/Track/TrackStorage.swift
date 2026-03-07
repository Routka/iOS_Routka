//
//  TrackStorage.swift
//  Routka
//
//  Created by vladukha on 16.02.2026.
//

import Foundation
import Combine
/// Enumerates the storage operations that can occur to a track (creation, deletion, update).
enum TrackStorageAction {
    /// Indicates a track was created.
    case created(Track)
    /// Indicates a track was deleted.
    case deleted(Track)
    /// Indicates a track was updated.
    case updated(Track)
}

/// Abstraction for components that provide persistent storage and retrieval of tracks.
/// Defines CRUD methods and a publisher for storage action events.
protocol TrackStorageProtocol {
    /// Retrieves all tracks that start on the given date.
    func getTracks(for date: Date, ofType trackType: TrackType) async -> [Track]
    /// Retrieves all tracks in storage.
    func getAllTracks(ofType trackType: TrackType) async -> [Track]
    /// Adds a new track to storage.
    func addTrack(_ track: Track) async throws
    /// Deletes the specified track from storage.
    func deleteTrack(_ track: Track) async
    /// Updates the specified track in storage.
    func updateTrack(_ track: Track) async throws
    /// Publisher that notifies about storage actions performed on tracks.
    var actionPublisher: PassthroughSubject<TrackStorageAction, Never> { get }
    func getTrack(by id: String) async -> Track?
    func getTracks(withParentID parent: String, ofType trackType: TrackType) async -> [Track]
}
