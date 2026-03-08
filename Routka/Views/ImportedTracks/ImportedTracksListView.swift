//
//  ImportedTracksListView.swift
//  Routka
//
//  Created by vladukha on 08.03.2026.
//
import SwiftUI
import Combine
import SimpleRouter

extension Route where Self == MeasuredTrackListView.RouteBuilder {
    /// View of a detailed measured track view
    static func importedTracks(vm: any ImportedTracksListViewModelProtocol,
                            dependencies: DependencyManager) -> ImportedTracksListView.RouteBuilder {
        ImportedTracksListView.RouteBuilder(vm: vm, dependencies: dependencies)
    }
}


struct ImportedTracksListView: View {
    struct RouteBuilder: Route {
        let id: String = UUID.init().uuidString
        static func == (lhs: ImportedTracksListView.RouteBuilder, rhs: ImportedTracksListView.RouteBuilder) -> Bool {
            lhs.id == rhs.id
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        let vm: any ImportedTracksListViewModelProtocol
        let dependencies: DependencyManager

        func build() -> AnyView {
            AnyView(ImportedTracksListView(vm: vm, dependencies: dependencies))
        }
    }
    
    @State private var vm: any ImportedTracksListViewModelProtocol
    private let dependencies: DependencyManager
    @AppStorage("speedunit") var speedUnit: String = "km/h"

    init(vm: any ImportedTracksListViewModelProtocol,
         dependencies: DependencyManager) {
        _vm = .init(wrappedValue: vm)
        self.dependencies = dependencies
    }

    var body: some View {
        ScrollView {
                LazyVStack(spacing: 15) {
                    if case .list(let tracks) = vm.screenState {
                        ForEach(tracks, id: \.id) { track in
                            Button {
                                dependencies.routers[dependencies.tabRouter.selectedTab]?.push(
                                    .trackDetail(track: track, dependencies: dependencies))
                            } label: {
                                TrackHistoryCellView(track: track,
                                                     unit: UnitSpeed.byName(speedUnit),
                                                     dependencies: dependencies)
                                .containerRelativeFrame([.horizontal, .vertical]) { size, axis in
                                    if axis == .vertical {
                                        return size * 0.4
                                    } else {
                                        return size
                                    }
                                }
                            }
                        }
                    }
                }
        }
        .contentMargins(.horizontal, 10, for: .scrollContent)
        .frame(maxWidth: .infinity)
        .animation(.default, value: vm.screenState)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { // Specify placement
                Button {
                    Task {
                        dependencies.trackFileService.showImporter()
                    }
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
            }
        }
        .navigationTitle("Imported Tracks")
        .overlay {
            if case .list(let array) = vm.screenState,
               array.isEmpty {
                emptyTag
            }
        }
        .background(Color.cyan.gradient.opacity(0.05))
    }
    
    private var emptyTag: some View {
        VStack(spacing: 20) {
            
            Text("You have no imported tracks.")
                .font(.largeTitle)
                .opacity(0.6)
                .transition(.opacity)
                .multilineTextAlignment(.center)
            Button {
                Task {
                    dependencies.trackFileService.showImporter()
                }
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Import from files")
                }
                .font(.title2)
            }
        }
        .padding(.horizontal)
    }
}

/// Preview model for ImportedTracksListView
@Observable
private final class PreviewImportedModel: ImportedTracksListViewModelProtocol {
    var screenState: ListState<Track> = .list([
        .newFilledTrack(),
        .newFilledTrack(),
        .newFilledTrack()
    ])
}

#Preview {
    NavigationView {
        ImportedTracksListView(vm: PreviewImportedModel(), dependencies: .mock())
    }
}
