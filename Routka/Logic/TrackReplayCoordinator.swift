//
//  TrackReplayCoordinator.swift
//  Routka
//
//  Created by vladukha on 20.02.2026.
//

import Foundation
import Combine

nonisolated let trackReplayCoordinatorLogger = MainLogger("TrackReplayCoordinator")

enum TrackReplayAction {
    case select(Track)
    case deselect
}

protocol TrackReplayCoordinatorProtocol: Actor {
    nonisolated
    var selectedTrackPublisher: PassthroughSubject<TrackReplayAction, Never> { get }
    func selectTrackToReplay(_ track: Track)
    func deselectReplay()
}

nonisolated
final actor TrackReplayCoordinator: TrackReplayCoordinatorProtocol {
    nonisolated
    let selectedTrackPublisher: PassthroughSubject<TrackReplayAction, Never> = .init()
    
    func selectTrackToReplay(_ track: Track) {
        selectedTrackPublisher.send(.select(track))
        trackReplayCoordinatorLogger.log("Selected track for replay",
                                         message: "trackID: \(track.id)",
                                         .info)
    }
    
    func deselectReplay() {
        selectedTrackPublisher.send(.deselect)
        trackReplayCoordinatorLogger.log("Deselected replay track", .info)
    }
}
