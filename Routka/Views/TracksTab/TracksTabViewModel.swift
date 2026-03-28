//
//  TracksTabViewModel.swift
//  Routka
//
//  Created by vladukha on 08.03.2026.
//
import SwiftUI
import Combine

@Observable
final class TracksTabViewModel: TracksTabViewModelProtocol {
    let showLimit = 6
    
    var historyTracks: [Track] = []
    var measuredTracks: [MeasuredTrack] = []
    var importedTracks: [Track] = []
    
    private let dependencies: DependencyManager
    private var cancellables: Set<AnyCancellable> = []
    
    init(dependencies: DependencyManager) {
        self.dependencies = dependencies
        
        Task {
            let historyTracks = await dependencies.storageService
                .getAllTracks(ofType: .record, limit: showLimit)
            withAnimation {
                self.historyTracks = historyTracks
            }
        }
        Task {
            let importedTracks = await dependencies.storageService
                .getAllTracks(ofType: .import, limit: showLimit)
            withAnimation {
                self.importedTracks = importedTracks
            }
        }
        
        Task {
            let measuredTracks = await dependencies.measuredTrackStorageService
                .getMeasuredTracks(limit: showLimit)
            withAnimation {
                self.measuredTracks = measuredTracks
            }
        }
        
        self.dependencies.storageService
            .actionPublisher
            .sink { [weak self] action in
                self?.receiveAction(action)
            }
            .store(in: &cancellables)
        self.dependencies.measuredTrackStorageService
            .actionPublisher
            .sink { [weak self] action in
                self?.receiveAction(action)
            }
            .store(in: &cancellables)
    }
    
    private func receiveAction(_ action: MeasuredTrackStorageAction) {
        switch action {
        case .created(let track):
            guard measuredTracks.count < showLimit else { return }
            // Insert track by descending startDate order
            if let index = measuredTracks.firstIndex(where: { $0.startDate > track.startDate }) {
                measuredTracks.insert(track, at: index)
            } else {
                measuredTracks.insert(track, at: 0)
            }
        case .deleted(let track):
            measuredTracks.removeAll(where: { $0.id == track.id })
        case .updated(let track):
            if let index = measuredTracks.firstIndex(where: { $0.id == track.id }) {
                measuredTracks[index] = track
            }
        }
    }
    
    private func receiveAction(_ action: TrackStorageAction) {
        withAnimation {
            switch action {
            case .created(let track):
                switch track.trackType {
                case .record:
                    let index = self.historyTracks.firstIndex(where: { $0.startDate > track.startDate }) ?? 0
                    self.historyTracks.insert(track, at: index)
                    if historyTracks.count > showLimit {
                        self.historyTracks.removeLast(1)
                    }
                case .import:
                    let index = self.importedTracks.firstIndex(where: { $0.startDate > track.startDate }) ?? 0
                    self.importedTracks.insert(track, at: index)
                    if importedTracks.count > showLimit {
                        self.importedTracks.removeLast(1)
                    }
                case .measurement:
                    break
                }
                
            case .deleted(let track):
                self.historyTracks.removeAll(where: { $0.id == track.id })
                self.importedTracks.removeAll(where: { $0.id == track.id })
            case .updated(let track):
                if let index = self.historyTracks.firstIndex(where: { $0.id == track.id }) {
                    self.historyTracks[index] = track
                } else if let index = self.importedTracks.firstIndex(where: { $0.id == track.id }) {
                    self.importedTracks[index] = track
                }
            }
        }
    }
}
