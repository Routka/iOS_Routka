//
//  ImportedTracksListView.swift
//  Routka
//
//  Created by vladukha on 08.03.2026.
//
import SwiftUI
import Combine

struct ImportedTracksListView: View {
    
    @State private var vm: any ImportedTracksListViewModelProtocol
    @AppStorage("speedunit") var speedUnit: String = "km/h"

    init(vm: any ImportedTracksListViewModelProtocol) {
        _vm = .init(wrappedValue: vm)
    }

    var body: some View {
        ScrollView {
                LazyVStack(spacing: 15) {
                    if case .list(let tracks) = vm.screenState {
                        ForEach(tracks, id: \.id) { track in
                            Button {
                                vm.openTrack(track)
                            } label: {
                                vm.trackHistoryCell(track,
                                                    unitSpeed: UnitSpeed.byName(speedUnit))
                                .view
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
                    vm.showImporter()
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
        .defaultBackground()
    }
    
    private var emptyTag: some View {
        VStack(spacing: 20) {
            
            Text("You have no imported tracks.")
                .font(.largeTitle)
                .opacity(0.6)
                .transition(.opacity)
                .multilineTextAlignment(.center)
            Button {
                vm.showImporter()
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
    func openTrack(_ track: Track) {
    }
    
    func trackHistoryCell(_ track: Track, unitSpeed: UnitSpeed) -> TrackHistoryCellComponent {
        TrackHistoryCellMockComponentProvider().trackCell(track: track, unit: unitSpeed)
    }
    
    func showImporter() {
    }
    
    var screenState: ListState<Track> = .list([
        .newFilledTrack(),
        .newFilledTrack(),
        .newFilledTrack()
    ])
}

#Preview {
    NavigationView {
        ImportedTracksListView(vm: PreviewImportedModel())
    }
}
