//
//  TracksTabViewModel.swift
//  Routka
//
//  Created by vladukha on 08.03.2026.
//
import SwiftUI
import Combine

/// Navigation connecting layer for viewmodel <-> component
@MainActor
protocol TracksTabRouting: AnyObject {
    func openTrack(_ track: Track)
    func openImportedTracks()
    func openMeasuredTracks()
    func openTrackHistory()
    func openMeasuredTrack(_ measure: MeasuredTrack)
    func openMap()
}

/// Factory for creating child components from viewmodel -> component
@MainActor
protocol TracksTabComponentsFactory: AnyObject {
    func trackHistoryCell(track: Track, unitSpeed: UnitSpeed) -> TrackHistoryCellComponent
}

@Observable
final class TracksTabViewModel: TracksTabViewModelProtocol {
    func openTrack(_ track: Track) {
        // Delegate navigation intent to parent-owned router implementation.
        routing.openTrack(track)
    }
    
    
    func trackHistoryCellComponent(track: Track, unitSpeed: UnitSpeed) -> TrackHistoryCellComponent {
        self.componentsFactory.trackHistoryCell(track: track, unitSpeed: unitSpeed)
    }
    
    func openImportedTracks() {
        routing.openImportedTracks()
    }
    func openMeasuredTracks() {
        routing.openMeasuredTracks()
    }
    func openTrackHistory() {
        routing.openTrackHistory()
    }
    func openMeasuredTrack(_ measure: MeasuredTrack) {
        routing.openMeasuredTrack(measure)
    }
    func openMap() {
        routing.openMap()
    }
    
    func showImporter() {
        trackFileService.showImporter()
    }
    
    let showLimit = 6
    
    var historyTracks: [Track] = []
    var measuredTracks: [MeasuredTrack] = []
    var importedTracks: [Track] = []
    
    private var cancellables: Set<AnyCancellable> = []
    private let trackFileService: any TrackFileServiceProtocol
    private let routing: any TracksTabRouting
    private let componentsFactory: any TracksTabComponentsFactory
    
    init(storageService: any TrackStorageProtocol,
         measuredTrackStorageService: any MeasuredTrackStorageProtocol,
         trackFileService: any TrackFileServiceProtocol,
         routing: any TracksTabRouting,
         componentsFactory: any TracksTabComponentsFactory) {
        self.trackFileService = trackFileService
        self.routing = routing
        self.componentsFactory = componentsFactory
        Task {
            let historyTracks = await storageService
                .getAllTracks(ofType: .record, limit: showLimit)
            withAnimation {
                self.historyTracks = historyTracks
            }
        }
        Task {
            let importedTracks = await storageService
                .getAllTracks(ofType: .import, limit: showLimit)
            withAnimation {
                self.importedTracks = importedTracks
            }
        }
        
        Task {
            let measuredTracks = await measuredTrackStorageService
                .getMeasuredTracks(limit: showLimit)
            withAnimation {
                self.measuredTracks = measuredTracks
            }
        }
        
        storageService
            .actionPublisher
            .sink { [weak self] action in
                self?.receiveAction(action)
            }
            .store(in: &cancellables)
        measuredTrackStorageService
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
