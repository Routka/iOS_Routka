import SwiftUI
import Combine

/// A view model responsible for managing a list of measured tracks.
/// It handles loading, updating, and deleting tracks while synchronizing with the underlying storage.
@Observable
final class MeasuredTrackListViewModel: MeasuredTrackListViewModelProtocol {
    /// The list of currently loaded measured tracks.
    private(set) var state: ListState<MeasuredTrack> = .loading
    private let storage: any MeasuredTrackStorageProtocol
    private var cancellables: Set<AnyCancellable> = []
    private let routing: any MeasuredTracksRouting

    init(measuredTrackStorageService: any MeasuredTrackStorageProtocol,
         routing: any MeasuredTracksRouting) {
        self.storage = measuredTrackStorageService
        self.routing = routing

        // Subscribe to storage actions
        storage.actionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                withAnimation {
                    self?.receiveAction(action)
                }
            }
            .store(in: &cancellables)

        // Load initial tracks asynchronously
        Task {
            let loaded = await storage.getMeasuredTracks(limit: nil)
            await MainActor.run {
                withAnimation {
                    self.state = .list(loaded)
                }
            }
        }
    }

    private func receiveAction(_ action: MeasuredTrackStorageAction) {
        switch action {
        case .created(let track):
            
            if case .list(var array) = state {
                let index = array.firstIndex(where: { $0.startDate > track.startDate }) ?? 0
                array.insert(track, at: index)
                self.state = .list(array)
            } else {
                self.state = .list([track])
            }
            
        case .deleted(let track):
            if case .list(var array) = state {
                array.removeAll(where: { $0.id == track.id })
                self.state = .list(array)
            }
        case .updated(let track):
            
            if case .list(var array) = state {
                if let index = array.firstIndex(where: { $0.id == track.id }) {
                    array[index] = track
                    self.state = .list(array)
                }
            }
        }
    }
    
    func openTrack(_ measuredTrack: MeasuredTrack) {
        routing.openTrack(measuredTrack)
    }

    /// Deletes measured tracks at the specified offsets asynchronously.
    /// - Parameter offsets: The index set of tracks to delete.
    func delete(at offsets: IndexSet) async {
        guard case .list(let array) = state else {
            return
        }
        let items = offsets.map { array[$0] }
        for item in items {
            await storage.deleteMeasuredTrack(item)
        }
    }
}

extension MeasuredTrack {
    var startDate: Date {
        self.track.points.first?.date ?? Date.distantPast
    }
}
