import SwiftUI
import SimpleRouter
extension Route where Self == MeasuredTrackListView.RouteBuilder {
    /// View of a detailed measured track view
    static func measuredTracks(vm: any MeasuredTrackListViewModelProtocol,
                            dependencies: DependencyManager) -> MeasuredTrackListView.RouteBuilder {
        MeasuredTrackListView.RouteBuilder(vm: vm, dependencies: dependencies)
    }
}


struct MeasuredTrackListView: View {
    struct RouteBuilder: Route {
        let id: String = UUID.init().uuidString
        static func == (lhs: MeasuredTrackListView.RouteBuilder, rhs: MeasuredTrackListView.RouteBuilder) -> Bool {
            lhs.id == rhs.id
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        let vm: any MeasuredTrackListViewModelProtocol
        let dependencies: DependencyManager

        func build() -> AnyView {
            AnyView(MeasuredTrackListView(vm: vm, dependencies: dependencies))
        }
    }
    
    @State private var viewModel: any MeasuredTrackListViewModelProtocol
    private let dependencies: DependencyManager

    init(vm: any MeasuredTrackListViewModelProtocol,
         dependencies: DependencyManager) {
        _viewModel = .init(wrappedValue: vm)
        self.dependencies = dependencies
    }

    var body: some View {
        List {
            if case .list(let array) = viewModel.state {
                ForEach(array, id: \.id) { measured in
                    Button {
                        #warning("fix navigation")
//                        Task {
//                            dependencies.routers[dependencies.tabRouter.selectedTab]?
//                                .push(.measuredTrackDetail(track: measured,
//                                                           dependencies: dependencies))
//                        }
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
    MeasuredTrackListView(vm: PreviewModel(), dependencies: .mock())
}

