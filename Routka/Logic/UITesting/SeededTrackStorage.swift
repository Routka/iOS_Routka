//
//  SeededTrackStorage.swift
//  Routka
//
//  Created by Codex on 14.08.2025.
//

import Combine
import Foundation

@MainActor
final class SeededTrackStorage: TrackStorageProtocol {
    let actionPublisher: PassthroughSubject<TrackStorageAction, Never> = .init()

    private lazy var commandReceiver = UITestCommandReceiver<SeededTrackStorageCommand>(
        key: UITestBridge.Key.trackStorageCommand
    ) { [weak self] command in
        self?.handle(command)
    }

    private var tracks: [Track] = []

    init() {
        self.commandReceiver.start()
    }

    func getTrack(by id: String) async -> Track? {
        self.tracks.first(where: { $0.id == id })
    }

    func getTracks(withParentID parent: String, ofType trackType: TrackType) async -> [Track] {
        self.tracks.filter { $0.parentID == parent && $0.trackType == trackType }
    }

    func getTracks(for date: Date, ofType trackType: TrackType) async -> [Track] {
        let calendar = Calendar.current
        return self.tracks.filter {
            $0.trackType == trackType && calendar.isDate($0.startDate, inSameDayAs: date)
        }
    }

    func getAllTracks(ofType trackType: TrackType, limit: Int?) async -> [Track] {
        let matchingTracks = self.tracks
            .filter { $0.trackType == trackType }
            .sorted { $0.startDate > $1.startDate }

        if let limit {
            return Array(matchingTracks.prefix(limit))
        }

        return matchingTracks
    }

    func addTrack(_ track: Track) async throws {
        self.tracks.insert(track, at: 0)
        self.actionPublisher.send(.created(track))
    }

    func deleteTrack(_ track: Track) async {
        self.tracks.removeAll(where: { $0.id == track.id })
        self.actionPublisher.send(.deleted(track))
    }

    func updateTrack(_ track: Track) async throws {
        guard let index = self.tracks.firstIndex(where: { $0.id == track.id }) else {
            return
        }

        self.tracks[index] = track
        self.actionPublisher.send(.updated(track))
    }

    private func handle(_ command: SeededTrackStorageCommand) {
        switch command.action {
        case .loadScenario:
            self.loadScenario(named: command.scenarioName)
        case .reset:
            self.tracks = []
        }
    }

    private func loadScenario(named scenarioName: String?) {
        _ = scenarioName
        self.tracks = []
    }
}
