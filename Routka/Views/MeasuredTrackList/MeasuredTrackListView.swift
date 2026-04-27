import SwiftUI

struct MeasuredTrackListView: View {
    
    @State private var viewModel: any MeasuredTrackListViewModelProtocol

    init(vm: any MeasuredTrackListViewModelProtocol) {
        _viewModel = .init(wrappedValue: vm)
    }

    var body: some View {
        List {
            if case .list(let array) = viewModel.state {
                ForEach(array, id: \.id) { measured in
                    Button {
                        viewModel.openTrack(measured)
                    } label: {
                        MeasuredTrackCellView(measured: measured)
                    }
                }
                .onDelete(perform: delete)
            }
        }
        .frame(maxWidth: .infinity)
        .listStyle(.insetGrouped)
        .animation(.default, value: viewModel.state)
        .overlay(content: {
            if case .list(let array) = viewModel.state,
               array.isEmpty  {
                Text("Empty measurements")
                    .font(.largeTitle)
                    .opacity(0.6)
                    .transition(.opacity)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        })
        .navigationTitle("Measured Tracks")
        .defaultBackground()
        .scrollContentBackground(.hidden)
    }

    private func delete(at offsets: IndexSet) {
        Task {
            await viewModel.delete(at: offsets)
        }
    }
}



@Observable
private final class PreviewModel: MeasuredTrackListViewModelProtocol {
    func openTrack(_ measuredTrack: MeasuredTrack) {
    }
    
    var state: ListState<MeasuredTrack> = .list([
        .init(id: "1", measurement: .reachingDistance(800, name: "1/2 mile"), track: .filledTrack),
        .init(id: "2", measurement: .reachingSpeed(800, name: "0-100 km/h"), track: .filledTrack),
        .init(id: "3", measurement: .reachingDistance(800, name: "1/2 mile"), track: .filledTrack),
        .init(id: "4", measurement: .reachingDistance(800, name: "1/2 mile"), track: .filledTrack),
    ]
    )
    
    func delete(at offsets: IndexSet) async {
//        self.tracks.removeAll()
    }
}

#Preview {
    NavigationView {
        MeasuredTrackListView(vm: PreviewModel())
    }
}

