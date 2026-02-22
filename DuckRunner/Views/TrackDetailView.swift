//
//  TrackDetailView.swift
//  DuckRunner
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

/// View model responsible for managing and providing detailed track data 
/// for presentation in the TrackDetailView.
final class TrackDetailViewModel: ObservableObject {
    /// The track instance whose details are displayed.
    private(set) var track: Track
    private let storageService: any TrackStorageProtocol
    
    /// Average speed of CLLocationSpeed
    @Published var averageSpeed: CLLocationSpeed?
    @Published var parentTrack: Track?
    @Published var children: [Track] = []
    
    /// Initializes the view model with a specific track.
    /// - Parameter track: The track to present.
    init(track: Track,
         dependencies: DependencyManager) {
        self.track = track
        self.storageService = dependencies.storageService
        Task {
            if let parentID = track.parentID,
               let parent = await storageService.getTrack(by: parentID){
                await MainActor.run {
                    self.parentTrack = parent
                }
            } else {
                let children = await storageService.getTracks(withParentID: track.id)
                await MainActor.run {
                    self.children = children
                }
            }
        }
    }
    
    func updateTrackType(to type: TrackType) async {
        self.track.type = type
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

/// A detailed view presenting comprehensive information about a finished track.
/// This view uses `TrackDetailViewModel` as its source of truth,
/// and serves as a detail/history screen displaying time, speed, distance,
/// and a map snippet of the track route.
struct TrackDetailView: View {
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
    @State private var mode: TrackType = .classical
    var body: some View {
        List {
            Section (header: Text("Track Details")){
                baseTrackInfo
            }
            Section {
                topSpeed
            }
            Section("Control") {
                Picker("Mode", selection: .init(get: {
                    vm.track.type
                }, set: { new in
                    Task {
                        await vm.updateTrackType(to: new)
                    }
                })) {
                    ForEach([TrackType.classical, .speedtrap], id: \.rawValue) { type in
                        Text(type.rawValue)
                            .tag(type)
                    }
                }
                Button("Replay Track") {
                    Task {
                        await dependencies.trackReplayCoordinator.selectTrackToReplay(vm.track)
                    }
                    dependencies.tabRouter.selectedTab = "map"
                }
                
                Button("Delete Track") {
                    Task {
                        await dependencies.storageService.deleteTrack(vm.track)
                    }
                }
            }
            
            if let parentTrack = vm.parentTrack {
                NavigationLink {
                    TrackDetailView(track: parentTrack,
                                    dependencies: dependencies)
                } label: {
                    Text("Parent track")
                }
            }
            
            if !vm.children.isEmpty  {
                Section("Replays") {
                    ForEach(vm.children, id: \.id) { track in
                        NavigationLink {
                            TrackDetailView(track: track,
                                            dependencies: dependencies)
                        } label: {
                            let date = track.startDate.toString(format: "EEE HH:mm")
                            Text("Replay at \(date)")
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
    }
    
    private var baseTrackInfo: some View {
        VStack {
            TrackMapSnippet(track: vm.track)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 15))
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

private actor TestCache: TrackMapSnippetCacheProtocol {
    func getSnippet(for track: Track, size: CGSize) async -> UIImage? {
        return nil
    }
    
    func cacheSnippet(_ snippet: UIImage, for track: Track, size: CGSize) async {
    }
}


#Preview {
    NavigationView {
        TrackDetailView(track: .filledTrack, dependencies: .mock())
    }
}
