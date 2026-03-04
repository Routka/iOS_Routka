import SwiftUI

struct MeasuredTrackListView: View {
    @State private var viewModel: any MeasuredTrackListViewModelProtocol

    init(vm: any MeasuredTrackListViewModelProtocol,
        dependencies: DependencyManager) {
        _viewModel = .init(wrappedValue: vm)
    }

    var body: some View {
        ScrollView {
            VStack {
                ForEach(viewModel.tracks, id: \.id) { track in
                    VStack(alignment: .leading) {
                        Text(track.measurement.name)
                        let firstDate = track.startDate
                            Text(firstDate, style: .date)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Material.thin)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
            }
            .padding(.horizontal)
        }
        .animation(.default, value: viewModel.tracks.count)
        .navigationTitle("Measured Tracks")
    }
}

@Observable
private final class PreviewModel: MeasuredTrackListViewModelProtocol {
    var tracks: [MeasuredTrack] = [
        .init(id: "1", measurement: .reachingDistance(800, name: "1/2 mile"), track: .filledTrack)
    ]
    
    
}

#Preview {
    MeasuredTrackListView(vm: PreviewModel(), dependencies: .mock())
}
