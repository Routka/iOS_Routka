import SwiftUI
import Combine

@Observable
final class MeasuredTrackListViewModel: MeasuredTrackListViewModelProtocol {
    private(set) var tracks: [MeasuredTrack] = []
    private let storage: any MeasuredTrackStorageProtocol
    private var cancellables: Set<AnyCancellable> = []

    init(dependencies: DependencyManager) {
        self.storage = dependencies.measuredTrackStorageService

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
            let loaded = await storage.getMeasuredTracks()
            await MainActor.run {
                withAnimation {
                    self.tracks = loaded
                }
            }
        }
    }

    private func receiveAction(_ action: MeasuredTrackStorageAction) {
        switch action {
        case .created(let track):
            // Insert track by descending startDate order
            if let index = tracks.firstIndex(where: { $0.startDate > track.startDate }) {
                tracks.insert(track, at: index)
            } else {
                tracks.insert(track, at: 0)
            }
        case .deleted(let track):
            tracks.removeAll(where: { $0.id == track.id })
        case .updated(let track):
            if let index = tracks.firstIndex(where: { $0.id == track.id }) {
                tracks[index] = track
            }
        }
    }
}

extension MeasuredTrack {
    var startDate: Date {
        self.track.points.first?.date ?? Date.distantPast
    }
}
