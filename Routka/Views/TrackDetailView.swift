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
import Combine
import SimpleRouter

/// View model responsible for managing and providing detailed track data 
/// for presentation in the TrackDetailView.
final class TrackDetailViewModel: ObservableObject {
    /// The track instance whose details are displayed.
    @Published private(set) var track: Track
    private let storageService: any TrackStorageProtocol
    
    /// Average speed of CLLocationSpeed
    @Published var averageSpeed: CLLocationSpeed?
    @Published var parentTrack: Track?
    @Published var children: [Track] = []
    
    private var cancellables: Set<AnyCancellable> = []
    private let dependencies: DependencyManager
    /// Initializes the view model with a specific track.
    /// - Parameter track: The track to present.
    init(track: Track,
         dependencies: DependencyManager) {
        self.track = track
        self.storageService = dependencies.storageService
        self.dependencies = dependencies
        self.storageService.actionPublisher
            .sink { [weak self] action in
                self?.receiveAction(action)
            }
            .store(in: &cancellables)
        Task {
            if let parentID = track.parentID,
               let parent = await storageService.getTrack(by: parentID){
                await MainActor.run {
                    self.parentTrack = parent
                }
            } else {
                let children = await storageService.getTracks(withParentID: track.id, ofType: .record)
                await MainActor.run {
                    self.children = children
                }
            }
        }
    }
    
    /// Handles updates from the storage (track creation, deletion, or update) to maintain the correct tracks list.
    private func receiveAction(_ action: TrackStorageAction) {
        withAnimation {
            switch action {
            case .deleted(let track):
                if track.id == self.track.id {
                    dependencies.routers[dependencies.tabRouter.selectedTab]?
                        .pop()
                }
                self.children.removeAll(where: {$0.id == track.id})
            case .updated(let track):
                if track.id == self.track.id {
                    self.track = track
                }
                if let indexOfChild = self.children.firstIndex(where: {$0.id == track.id}) {
                    self.children[indexOfChild] = track
                }
            case .created(let track):
                if track.parentID == self.track.id {
                    self.children.append(track)
                }
            }
        }
    }
    
    func updateTrackType(to type: ReplayMode) async {
        self.track.replayMode = type
        try? await storageService.updateTrack(track)
    }
    
    func calculateAverageSpeed() {
        let points = track.points
        guard !points.isEmpty,
        let stopDate = track.stopDate else {
            return
        }

        // Calculate total distance traveled
        let totalDistance = points.totalDistance()
        
        // Calculate total time (in seconds)
        let totalTime = (stopDate.timeIntervalSince(track.startDate))
        
        // Guard against zero or near-zero time
        guard totalTime > 0 else {
            return
        }

        // Average speed in m/s
        let averageSpeedInMetersPerSecond = totalDistance / totalTime
        
        // Set the average speed (m/s)
        self.averageSpeed = CLLocationSpeed(averageSpeedInMetersPerSecond)
    }
    
    
}

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
    @StateObject private var vm: TrackDetailViewModel
    
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
            if vm.track.parentID == nil {
                Button {
                    Task {
                        await dependencies.trackReplayCoordinator.selectTrackToReplay(vm.track)
                    }
                    dependencies.tabRouter.selectedTab = "map"
                } label: {
                    Label("Replay the track", systemImage: "repeat")
                }
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
            if vm.track.trackType != .import {
                editSection
            }
            if vm.children.isEmpty {
                Button(role: .destructive) {
                    Task {
                        await dependencies.storageService.deleteTrack(vm.track)
                    }
                } label: {
                    Label("Delete track", systemImage: "trash")
                        .foregroundStyle(.red)
                }
            }
            
            
            if !vm.children.isEmpty  {
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
        .navigationTitle("\(vm.track.startDate.toString(style: .medium)) Track")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if vm.track.trackType != .import,
               vm.track.replayMode != .replay {
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
    }
    
    private var editSection: some View {
        Section("Edit") {
            if vm.track.replayMode != .replay {
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
            
            if vm.track.parentID == nil,
               vm.children.isEmpty {
                Button {
                    dependencies.routers[dependencies.tabRouter.selectedTab]?
                        .push(.trackTrim(track: vm.track,
                                         dependencies: dependencies))
                } label: {
                    Label("Edit track", systemImage: "timeline.selection")
                }
            }
        }
    }
    
    private var baseTrackInfo: some View {
        VStack(spacing: 8) {
            MapSnippetView(mapSnippetCache: dependencies.mapSnippetCache,
                           mapSnapshotGenerator: dependencies.mapSnapshotGenerator,
                           track: vm.track)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 0)
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
        TrackDetailView(track: .filledTrack, dependencies: .mock())
    }
}
