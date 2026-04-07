//
//  SeededMeasuredTrackStorage.swift
//  Routka
//
//  Created by Codex on 14.08.2025.
//

import Combine
import Foundation

@MainActor
final class SeededMeasuredTrackStorage: MeasuredTrackStorageProtocol {
    let actionPublisher: PassthroughSubject<MeasuredTrackStorageAction, Never> = .init()

    private lazy var commandReceiver = UITestCommandReceiver<SeededMeasuredTrackStorageCommand>(
        key: UITestBridge.Key.measuredTrackStorageCommand
    ) { [weak self] command in
        self?.handle(command)
    }

    private var tracks: [MeasuredTrack] = []

    init() {
        self.commandReceiver.start()
    }

    func getMeasuredTracks(limit: Int?) async -> [MeasuredTrack] {
        if let limit {
            return Array(self.tracks.prefix(limit))
        }

        return self.tracks
    }

    func addMeasuredTrack(_ track: MeasuredTrack) async {
        self.tracks.insert(track, at: 0)
        self.actionPublisher.send(.created(track))
    }

    func deleteMeasuredTrack(_ track: MeasuredTrack) async {
        self.tracks.removeAll(where: { $0.id == track.id })
        self.actionPublisher.send(.deleted(track))
    }

    func getShortestMeasuredTrack(named name: String) async -> MeasuredTrack? {
        self.tracks
            .filter { $0.measurement.name == name }
            .min(by: { self.duration(of: $0.track) < self.duration(of: $1.track) })
    }

    private func handle(_ command: SeededMeasuredTrackStorageCommand) {
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

    private func duration(of track: Track) -> TimeInterval {
        guard let firstDate = track.points.first?.date,
              let lastDate = track.points.last?.date else {
            return 0
        }

        return lastDate.timeIntervalSince(firstDate)
    }
}
