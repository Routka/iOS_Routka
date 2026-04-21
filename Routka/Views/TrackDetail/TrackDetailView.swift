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
import NeedleFoundation

//extension Route where Self == TrackDetailView.RouteBuilder {
//    /// View of a detailed track info
//    static func trackDetail(track: Track,
//                            dependencies: DependencyManager) -> TrackDetailView.RouteBuilder {
//        TrackDetailView.RouteBuilder(vm: .init(track: track,
//                                               storageService: dependencies.storageService,
//                                               routers: dependencies.routers,
//                                               tabRouter: dependencies.tabRouter))
//    }
//}

protocol TrackDetailDependency: Dependency {
    var storageService: any TrackStorageProtocol { get }
    var tabRouter: any TabRouterProtocol { get }
    var routers: [String: Router] { get }
    var trackFileService: any TrackFileServiceProtocol { get }
    var trackReplayCoordinator: any TrackReplayCoordinatorProtocol { get }
}


nonisolated final class TrackDetailComponent: Component<TrackDetailDependency> {
    private let track: Track
    
    init(parent: Scope, track: Track) {
        self.track = track
        super.init(parent: parent)
    }
    
    var mapSnippet: MapSnippetComponent {
        MapSnippetComponent(parent: self, track: track)
    }
    
    @MainActor
    var viewModel: TrackDetailViewModel {
        TrackDetailViewModel(track: track,
                             storageService: dependency.storageService,
                             routers: dependency.routers,
                             tabRouter: dependency.tabRouter,
                             trackFileService: dependency.trackFileService,
                             trackReplayCoordinator: dependency.trackReplayCoordinator,
                             component: self)
    }
    
    @MainActor
    var view: TrackDetailView {
        TrackDetailView(vm: viewModel)
    }
    
    @MainActor
    var trackMapComponent: TrackMapComponent {
        TrackMapComponent(parent: self, track: track)
    }
    
}


/// A detailed view presenting comprehensive information about a finished track.
/// This view uses `TrackDetailViewModel` as its source of truth,
/// and serves as a detail/history screen displaying time, speed, distance,
/// and a map snippet of the track route.
struct TrackDetailView: View {
    struct RouteBuilder: Route {
        static func == (lhs: TrackDetailView.RouteBuilder, rhs: TrackDetailView.RouteBuilder) -> Bool {
            lhs.vm.track == rhs.vm.track
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(vm.track)
        }
        
        let vm: TrackDetailViewModel

        func build() -> AnyView {
            AnyView(TrackDetailView(vm: vm))
        }
    }
    
    
    /// View model instance managing the track data and logic.
    @State private var vm: TrackDetailViewModel
    /// User preference stored for the speed unit (e.g., km/h or mph).
    @AppStorage("speedunit") var speedUnit: String = "km/h"
    
    /// Creates the detail view with the given track.
    /// - Parameter track: The track to be detailed.
    init(vm: TrackDetailViewModel) {
        self._vm = .init(initialValue: vm)
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
                if vm.parentTrack != nil {
                    Button("Original route") {
                        vm.openOriginalRoute()
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
                    vm.deleteTrack()
                } label: {
                    Label("Delete track", systemImage: "trash")
                        .foregroundStyle(.red)
                }
            }
            
            
            if vm.showReplaysSection {
                Section("Replays") {
                    ForEach(vm.children, id: \.id) { track in
                        Button {
                            vm.openChildTrack(track)
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
                        vm.exportTrack()
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
                vm.replayTrack()
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
                        Text(LocalizedStringKey(type.rawValue))
                            .tag(type)
                    }
                }
            }
            
            if vm.showTrimButton {
                Button {
                    vm.openTrackTrim()
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
                vm.openTrackMap()
            } label: {
                Group {
                    vm.mapSnippetComponent.mapSnippet
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 0)
            }
            .accessibilityIdentifier("mapDetailButton")
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



#warning("fix preview")
//#Preview {
//    NavigationView {
//        var track = Track(id: "", points: .roadInSPB, parentID: nil)
//        track.replayMode = .classical
//        return TrackDetailView(track: track, dependencies: .mock())
//    }
//}
