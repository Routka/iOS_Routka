import SwiftUI

struct MeasuredTrackListView: View {
    @State private var viewModel: any MeasuredTrackListViewModelProtocol
    private let dependencies: DependencyManager

    init(vm: any MeasuredTrackListViewModelProtocol,
         dependencies: DependencyManager) {
        _viewModel = .init(wrappedValue: vm)
        self.dependencies = dependencies
    }

    var body: some View {
        List {
            ForEach(viewModel.tracks, id: \.id) { measured in
                Button {
                    Task {
                        dependencies.routers[dependencies.tabRouter.selectedTab]?
                            .push(.measuredTrackDetail(track: measured,
                                                       dependencies: dependencies))
                    }
                } label: {
                    MeasuredTrackCellView(measured: measured)
                }
            }
            .onDelete(perform: delete)
        }
        .frame(maxWidth: .infinity)
        .listStyle(.insetGrouped)
        .animation(.default, value: viewModel.tracks.count)
        .navigationTitle("Measured Tracks")
    }

    private func delete(at offsets: IndexSet) {
        Task {
            await viewModel.delete(at: offsets)
        }
    }
}



@Observable
private final class PreviewModel: MeasuredTrackListViewModelProtocol {
    func delete(at offsets: IndexSet) async {
        self.tracks.removeAll()
    }
    
    var tracks: [MeasuredTrack] = [
        .init(id: "1", measurement: .reachingDistance(800, name: "1/2 mile"), track: .filledTrack),
        .init(id: "2", measurement: .reachingSpeed(800, name: "0-100 km/h"), track: .filledTrack),
        .init(id: "3", measurement: .reachingDistance(800, name: "1/2 mile"), track: .filledTrack),
        .init(id: "4", measurement: .reachingDistance(800, name: "1/2 mile"), track: .filledTrack),
    ]
    
    
}

#Preview {
    MeasuredTrackListView(vm: PreviewModel(), dependencies: .mock())
}

