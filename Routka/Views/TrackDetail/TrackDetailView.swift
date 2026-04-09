//
//  TrackDetailView.swift
//  Routka
//
//  Created by vladukha on 16.02.2026.
//
// This file contains the UI components and view model necessary to present
// detailed information about a recorded track. It displays key metrics such as
// time, top speed, distance, and a map snippet showing the track route,
// providing users with a comprehensive history and summary of their finished tracks.
//

import SwiftUI
import MapKit
import SimpleRouter

extension Route where Self == TrackDetailView.RouteBuilder {
    /// View of a detailed track info
    static func trackDetail(track: Track,
                            dependencies: DependencyManager) -> TrackDetailView.RouteBuilder {
        TrackDetailView.RouteBuilder(track: track, dependencies: dependencies)
    }
}


/// A detailed view presenting comprehensive information about a finished track.
/// This view uses `TrackDetailViewModel` as its source of truth,
/// and serves as a detail/history screen displaying time, speed, distance,
/// and a map snippet of the track route.
struct TrackDetailView: View {
    struct RouteBuilder: Route {
        static func == (lhs: TrackDetailView.RouteBuilder, rhs: TrackDetailView.RouteBuilder) -> Bool {
            lhs.track == rhs.track
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(track)
        }
        
        let track: Track
        let dependencies: DependencyManager

        func build() -> AnyView {
            AnyView(TrackDetailView(track: track,
                                    dependencies: dependencies))
        }
    }
    
    
    /// View model instance managing the track data and logic.
    @State private var vm: TrackDetailViewModel
    
    /// User preference stored for the speed unit (e.g., km/h or mph).
    @AppStorage("speedunit") var speedUnit: String = "km/h"
    
    private let dependencies: DependencyManager
    
    /// Creates the detail view with the given track.
    /// - Parameter track: The track to be detailed.
    init(track: Track,
         dependencies: DependencyManager) {
        self._vm = .init(wrappedValue: .init(track: track, dependencies: dependencies))
        self.dependencies = dependencies
    }
    
    var body: some View {
        List {
            Section (header: Text("Track Details")){
                baseTrackInfo
            }
            if vm.showReplayButton  {
                replaySection
            }
            
            Section {
                if let parentTrack = vm.parentTrack {
                    Button("Original route") {
                        dependencies.routers[dependencies.tabRouter.selectedTab]?.push(.trackDetail(track: parentTrack, dependencies: dependencies))
                    }
                }
                TrackSpeedStatsView(track: vm.track, parentTrack: vm.parentTrack)
                    .frame(height: 200)
                topSpeed
            }
            if vm.showEditSection {
                editSection
            }
            if vm.showDeleteTrackButton {
                Button(role: .destructive) {
                    Task {
                        await dependencies.storageService.deleteTrack(vm.track)
                    }
                } label: {
                    Label("Delete track", systemImage: "trash")
                        .foregroundStyle(.red)
                }
            }
            
            
            if vm.showReplaysSection {
                Section("Replays") {
                    ForEach(vm.children, id: \.id) { track in
                        Button {
                            dependencies.routers[dependencies.tabRouter.selectedTab]?.push(.trackDetail(track: track, dependencies: dependencies))
                        } label: {
                            let date = track.startDate.toString(format: "EEE HH:mm")
                            Text("Replay as of \(date)")
                        }
                    }
                }
            }
            
        }
        .onAppear(perform: {
            self.vm.calculateAverageSpeed()
        })
        .navigationTitle(vm.track.displayTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if vm.showExportButton {
                ToolbarItem(placement: .navigationBarTrailing) { // Specify placement
                    Button {
                        Task {
                            dependencies.trackFileService.exportTrack(vm.track)
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .defaultBackground()
        .scrollContentBackground(.hidden)
    }
    
    private var replaySection: some View {
        Section(LocalizedStringKey(vm.track.replayMode.rawValue)) {
            Group {
                switch vm.track.replayMode {
                case .classical:
                    Text("classical replay hint")
                case .speedtrap:
                    let requiredSpeed: String = Int(SettingsService.shared.speedToAutoStartReplay).description
                    Text("speedtrap replay hint \(requiredSpeed) \(speedUnit)")
                case .replay:
                    EmptyView()
                }
            }
            .font(.caption)
            .opacity(0.7)
            .accessibilityIdentifier("replayHint")
            Button {
                Task {
                    await dependencies.trackReplayCoordinator.selectTrackToReplay(vm.track)
                }
                dependencies.tabRouter.selectedTab = "map"
            } label: {
                Label("Replay the track", systemImage: "repeat")
            }
        }
    }
    
    private var editSection: some View {
        Section("Edit") {
            if vm.showModeEditButton {
                Picker("Mode", selection: .init(get: {
                    vm.track.replayMode
                }, set: { new in
                    Task {
                        await vm.updateTrackType(to: new)
                    }
                })) {
                    ForEach([ReplayMode.classical, .speedtrap], id: \.rawValue) { type in
                        Text(type.rawValue.capitalized)
                            .tag(type)
                    }
                }
            }
            
            if vm.showTrimButton {
                Button {
                    dependencies.routers[dependencies.tabRouter.selectedTab]?
                        .push(.trackTrim(track: vm.track,
                                         dependencies: dependencies))
                } label: {
                    Label("Edit track", systemImage: "timeline.selection")
                }
                .accessibilityIdentifier("editTrackButton")
            }
        }
    }
    
    private var baseTrackInfo: some View {
        VStack(spacing: 8) {
            Button {
                dependencies.routers[dependencies.tabRouter.selectedTab]?
                    .push(.mapTrackDetail(track: vm.track, dependencies: dependencies))
            } label: {
                MapSnippetView(mapSnippetCache: dependencies.mapSnippetCache,
                               mapSnapshotGenerator: dependencies.mapSnapshotGenerator,
                               track: vm.track)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 0)
            }
            mainStat
        }
    }
    
    @ViewBuilder
    private var topSpeed: some View {
        if let speedPoint = vm.track.points.topSpeedPoint() {
            let unitSpeed = UnitSpeed.byName(speedUnit)
            HStack {
                VStack {
                    let interval = speedPoint.date.timeIntervalSince(vm.track.startDate)
                    Text("at " + (TimeIntervalFormatter.string(from: interval) ?? "_"))
                        .font(.caption2)
                        .foregroundStyle(Color.primary)
                        .opacity(0.5)
                    TrackTopSpeedView(speedPoint.speed,
                                      displayUnit: unitSpeed)
                }
                .padding(.horizontal)
                .padding(.vertical, 5)
                .glassEffect(.regular.tint(.cyan.opacity(0.1)), in: RoundedRectangle(cornerRadius: 10))
                Spacer()
            }
        }
    }
    
    private var mainStat: some View {
        HStack {
            let unitSpeed = UnitSpeed.byName(speedUnit)
            CompactTrackDistanceView(distance: vm.track.points.totalDistance(),
                                     unit: unitSpeed)
            Spacer()
            if let stopDate = vm.track.stopDate {
                CompactTrackDurationView(startDate: vm.track.startDate,
                                         stopDate: stopDate)
            }
            Spacer()
           if let averageSpeed = vm.averageSpeed {
               CompactTrackAvgSpeedView(speed: averageSpeed,
                                        unit: unitSpeed)
            }
        }
    }
}



#Preview {
    NavigationView {
        var track = Track(id: "", points: .roadInSPB, parentID: nil)
        track.replayMode = .classical
        return TrackDetailView(track: track, dependencies: .mock())
    }
}
