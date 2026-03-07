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
    /// - Parameter dependencies: A dependency manager providing required services such as the track storage.
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
                    let tracks = await self.storage.getTracks(for: date, ofType: .record)
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
    private func receiveAction(_ action: TrackStorageAction) {
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
