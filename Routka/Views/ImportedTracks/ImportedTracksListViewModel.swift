//
//  ImportedTracksListViewModel.swift
//  Routka
//
//  Created by vladukha on 08.03.2026.
//
import SwiftUI
import Combine

/// View model for the imported tracks list
@Observable
final class ImportedTracksListViewModel: ImportedTracksListViewModelProtocol {
    private(set) var screenState: ListState<Track> = .loading

    private let storage: any TrackStorageProtocol
    private let componentsFactory: any ImportedTracksComponentsFactory
    private let routing: any ImportedTracksRouting
    private let trackFileService: any TrackFileServiceProtocol
    
    private var cancellables: Set<AnyCancellable> = []

    init(storageService: any TrackStorageProtocol,
         componentsFactory: any ImportedTracksComponentsFactory,
         routing: any ImportedTracksRouting,
         trackFileService: any TrackFileServiceProtocol) {
        self.storage = storageService
        self.componentsFactory = componentsFactory
        self.routing = routing
        self.trackFileService = trackFileService
        
        self.storage.actionPublisher
            .sink { [weak self] action in
                self?.receiveAction(action)
            }
            .store(in: &cancellables)
        
        // Load imported tracks
        Task {
            let loaded = await storage.getAllTracks(ofType: .import, limit: nil)
            withAnimation {
                self.screenState = .list(loaded)
            }
        }
    }
    
    /// Handles updates from the storage (track creation, deletion, or update) to maintain the correct tracks list.
    private func receiveAction(_ action: TrackStorageAction) {
        withAnimation {
            switch action {
            case .created(let track):
                guard track.trackType == .import else { return }
                if case .list(var array) = screenState {
                    let index = array.firstIndex(where: { $0.startDate > track.startDate }) ?? 0
                    array.insert(track, at: index)
                    self.screenState = .list(array)
                } else {
                    self.screenState = .list([track])
                }
                
            case .deleted(let track):
                guard track.trackType == .import else { return }
                if case .list(var array) = screenState {
                    array.removeAll(where: { $0.id == track.id })
                    self.screenState = .list(array)
                }
            case .updated(let track):
                guard track.trackType == .import else { return }
                if case .list(var array) = screenState {
                    if let index = array.firstIndex(where: { $0.id == track.id }) {
                        array[index] = track
                        self.screenState = .list(array)
                    }
                }
            }
        }
    }
    
    func openTrack(_ track: Track) {
        routing.openTrack(track)
    }
    
    func trackHistoryCell(_ track: Track, unitSpeed: UnitSpeed) -> TrackHistoryCellComponent {
        componentsFactory.trackHistoryCell(track, unitSpeed)
    }
    
    func showImporter() {
        trackFileService.showImporter()
    }
}
