//
//  TrackHistoryViewModel.swift
//  DuckRunner
//
//  Created by vladukha on 16.02.2026.
//

import SwiftUI
import Combine

/// View model responsible for providing track history data and managing user selection of dates.
/// Tracks updates from the storage and exposes the current list of tracks and selected date for the UI.
final class TrackHistoryViewModel: TrackHistoryViewModelProtocol {
    /// The list of tracks for the selected date, published for UI updates.
    @Published private(set) var tracks: [Track] = []
    
    /// The date currently selected by the user in the UI.
    @Published var selectedDate: Date = .now
    
    /// Reference to the underlying storage mechanism for tracks.
    private let storage: any TrackStorageProtocol
    
    /// Holds Combine cancellables for subscriptions.
    private var cancellables: Set<AnyCancellable> = []
    
    
    
    /// Creates a new view model instance and subscribes to storage actions and date selection changes.
    init(dependencies: DependencyManager) {
        self.storage = dependencies.storageService
        self.storage.actionPublisher
            .sink { [weak self] action in
                self?.receiveAction(action)
            }
            .store(in: &cancellables)
        
        self.$selectedDate
            .sink { date in
                Task.detached { [weak self] in
                    guard let self else { return }
                    let tracks = await self.storage.getTracks(for: date)
                    await MainActor.run {
                        withAnimation {
                            self.tracks = tracks
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
    }
    
    /// Handles updates from the storage (track creation, deletion, or update) to maintain the correct tracks list.
    private func receiveAction(_ action: StorageAction) {
        withAnimation {
            switch action {
            case .created(let track):
                let index = self.tracks.firstIndex(where: { $0.startDate > track.startDate }) ?? 0
                self.tracks.insert(track, at: index)
            case .deleted(let track):
                self.tracks.removeAll(where: { $0.id == track.id })
            case .updated(let track):
                if let index = self.tracks.firstIndex(where: { $0.id == track.id }) {
                    self.tracks[index] = track
                }
            }
        }
    }
}
