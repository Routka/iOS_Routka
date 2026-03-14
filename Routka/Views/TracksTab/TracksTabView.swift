//
//  TracksTabView.swift
//  Routka
//
//  Created by vladukha on 08.03.2026.
//

import SwiftUI

struct TracksTabView: View {
    @AppStorage("speedunit") var speedUnit: String = "km/h"
    @State private var vm: any TracksTabViewModelProtocol
    private let dependencies: DependencyManager
    init(vm: any TracksTabViewModelProtocol,
         dependencies: DependencyManager) {
        self._vm = .init(wrappedValue: vm)
        self.dependencies = dependencies
    }
    
    var body: some View {
        ScrollView {
            historyTimeLine
            Divider()
            measuredTimeLine
            Divider()
            importedTimeLine
        }
        .contentMargins(.vertical, 10, for: .scrollContent)
        .frame(maxWidth: .infinity)
        
    }
    
    private var importedTimeLine: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Imported Tracks")
                    .font(.title)
                Spacer()
                Button {
                    dependencies.routers[dependencies.tabRouter.selectedTab]?.push(
                        .importedTracks(vm: ImportedTracksListViewModel(dependencies: dependencies),
                                        dependencies: dependencies))
                } label: {
                    Text("More")
                        .padding(10)
                }
                .glassEffect()
            }
                .padding(.horizontal, 10)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(vm.importedTracks) { track in
                        Button {
                            dependencies.routers[dependencies.tabRouter.selectedTab]?.push(
                                .trackDetail(track: track, dependencies: dependencies))
                        } label: {
                            TrackHistoryCellView(track: track,
                                                 unit: UnitSpeed.byName(speedUnit),
                                                 dependencies: dependencies)
                        }
                        .frame(height: 300)
                        .containerRelativeFrame(.horizontal)
                        
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.horizontal, 20, for: .scrollContent)
            if vm.importedTracks.isEmpty {
                VStack(spacing: 20) {
                    
                    Text("You have no imported tracks.")
                        .font(.title3)
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
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
            }
        }
    }
    
    private var historyTimeLine: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("History")
                    .font(.title)
                Spacer()
                Button {
                    dependencies.routers[dependencies.tabRouter.selectedTab]?.push(
                        .trackHistory(vm: TrackHistoryViewModel(dependencies: dependencies),
                                      dependencies: dependencies))
                } label: {
                    Text("More")
                        .padding(10)
                }
                .glassEffect()
            }
                .padding(.horizontal, 10)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(vm.historyTracks) { track in
                        Button {
                            dependencies.routers[dependencies.tabRouter.selectedTab]?.push(
                                .trackDetail(track: track, dependencies: dependencies))
                        } label: {
                            TrackHistoryCellView(track: track,
                                                 unit: UnitSpeed.byName(speedUnit),
                                                 dependencies: dependencies)
                        }
                        .frame(height: 300)
                        .containerRelativeFrame(.horizontal)
                        
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.horizontal, 20, for: .scrollContent)
            if vm.historyTracks.isEmpty {
                Text("Empty history")
                    .font(.title3)
                    .opacity(0.6)
                    .transition(.opacity)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
            }
        }
    }
    
    private var measuredTimeLine: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Measurements")
                    .font(.title)
                Spacer()
                Button {
                    dependencies.routers[dependencies.tabRouter.selectedTab]?.push(
                        .measuredTracks(vm: MeasuredTrackListViewModel(dependencies: dependencies),
                                      dependencies: dependencies))
                } label: {
                    Text("More")
                        .padding(10)
                }
                .glassEffect()
            }
                .padding(.horizontal, 10)
            ScrollView(.horizontal, showsIndicators: false) {
                let batches = vm.measuredTracks.chunks(of: 3)
                HStack(alignment: .top) {
                    ForEach(batches, id: \.hashValue) { batch in
                        VStack {
                            ForEach(batch) { measure in
                                Button {
                                    dependencies.routers[dependencies.tabRouter.selectedTab]?.push(
                                        .measuredTrackDetail(track: measure, dependencies: dependencies))
                                } label: {
                                    MeasuredTrackCellView(measured: measure)
                                        .padding(6)
                                        .background(Material.thin)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.horizontal, 20, for: .scrollContent)
            if vm.measuredTracks.isEmpty {
                Text("Empty measurements")
                    .font(.title3)
                    .opacity(0.6)
                    .transition(.opacity)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
            }
        }
    }
}
//
//let measureds: [MeasuredTrack] = [
//    .init(id: "1", measurement: .reachingDistance(30, name: "1/8 mill"), track: .filledTrack),
//    .init(id: "2", measurement: .reachingDistance(30, name: "1/8 mill"), track: .filledTrack),
//    .init(id: "3", measurement: .reachingDistance(30, name: "1/8 mill"), track: .filledTrack),
//    .init(id: "4", measurement: .reachingDistance(30, name: "1/8 mill"), track: .filledTrack),
//    .init(id: "5", measurement: .reachingDistance(30, name: "1/8 mill"), track: .filledTrack),
//    .init(id: "6", measurement: .reachingDistance(30, name: "1/8 mill"), track: .filledTrack),
//]


@Observable
private final class PreviewModel: TracksTabViewModelProtocol {
    var historyTracks: [Track] = []
    
    var measuredTracks: [MeasuredTrack] = []
    
    var importedTracks: [Track] = []
    
    
}

#Preview {
    TracksTabView(vm: PreviewModel(), dependencies: .mock())
}
