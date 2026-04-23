//
//  TrackHistoryViewModel.swift
//  Routka
//
//  Created by vladukha on 16.02.2026.
//

import SwiftUI
import Combine

/// A view model that manages the track history and the user's date selection.
/// 
/// It provides a published list of tracks corresponding to the selected date and listens to updates from the storage.
/// When the selected date changes or the underlying storage updates, the tracks list is refreshed accordingly.
@Observable
final class TrackHistoryViewModel: TrackHistoryViewModelProtocol {
    /// The list of tracks for the selected date, published for UI updates.
    private(set) var state: ListState<Track> = .loading
    
    /// The date currently selected by the user in the UI.
    var selectedDate: Date = .now {
        didSet {
            fetchByDay()
        }
    }
    
    /// Reference to the underlying storage mechanism for tracks.
    private let storage: any TrackStorageProtocol
    private let routing: any TrackHistoryRouting
    private let componentsFactory: any TrackHistoryComponentsFactory
    
    /// Holds Combine cancellables for subscriptions.
    private var cancellables: Set<AnyCancellable> = []
    
    
    
    /// Creates a new view model instance and subscribes to storage actions and date selection changes.
    /// - Parameter dependencies: A dependency manager providing required services such as the track storage.
    init(storageService: any TrackStorageProtocol,
         routing: any TrackHistoryRouting,
         componentsFactory: any TrackHistoryComponentsFactory) {
        self.storage = storageService
        self.routing = routing
        self.componentsFactory = componentsFactory
        self.storage.actionPublisher
            .sink { [weak self] action in
                self?.receiveAction(action)
            }
            .store(in: &cancellables)
        fetchByDay()
    }
    
    func openTrack(_ track: Track) {
        routing.openTrack(track)
    }
    
    func trackCell(_ track: Track, unitSpeed: UnitSpeed) -> TrackHistoryCellComponent {
        componentsFactory.trackHistoryCell(track: track, unitSpeed: unitSpeed)
    }
    
    private func fetchByDay() {
        Task.detached { [weak self] in
            guard let self else { return }
            let tracks = await self.storage.getTracks(for: selectedDate, ofType: .record)
            await MainActor.run {
                withAnimation {
                    self.state = .list(tracks)
                }
            }
        }
    }
    
    /// Handles updates from the storage (track creation, deletion, or update) to maintain the correct tracks list.
    private func receiveAction(_ action: TrackStorageAction) {
        withAnimation {
            switch action {
            case .created(let track):
                guard track.trackType == .record else { return }
                if case .list(var array) = state {
                    let index = array.firstIndex(where: { $0.startDate > track.startDate }) ?? 0
                    array.insert(track, at: index)
                    self.state = .list(array)
                } else {
                    self.state = .list([track])
                }
                
            case .deleted(let track):
                guard track.trackType == .record else { return }
                if case .list(var array) = state {
                    array.removeAll(where: { $0.id == track.id })
                    self.state = .list(array)
                }
            case .updated(let track):
                guard track.trackType == .record else { return }
                if case .list(var array) = state {
                    if let index = array.firstIndex(where: { $0.id == track.id }) {
                        array[index] = track
                        self.state = .list(array)
                    }
                }
            }
        }
    }
}
