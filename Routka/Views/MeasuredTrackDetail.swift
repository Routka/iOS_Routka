//
//  TrackDetailView 2.swift
//  Routka
//
//  Created by vladukha on 06.03.2026.
//
import SwiftUI
import CoreLocation
import SimpleRouter

extension Route where Self == MeasuredTrackDetailView.RouteBuilder {
    /// View of a detailed measured track view
    static func measuredTrackDetail(track: MeasuredTrack,
                            dependencies: DependencyManager) -> MeasuredTrackDetailView.RouteBuilder {
        MeasuredTrackDetailView.RouteBuilder(track: track, dependencies: dependencies)
    }
}

struct MeasuredTrackDetailView: View {
    struct RouteBuilder: Route {
        static func == (lhs: MeasuredTrackDetailView.RouteBuilder, rhs: MeasuredTrackDetailView.RouteBuilder) -> Bool {
            lhs.track == rhs.track
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(track)
        }
        
        let track: MeasuredTrack
        let dependencies: DependencyManager

        func build() -> AnyView {
            AnyView(MeasuredTrackDetailView(measuredTrack: track,
                                    dependencies: dependencies))
        }
    }
    
    /// User preference stored for the speed unit (e.g., km/h or mph).
    @AppStorage("speedunit") var speedUnit: String = "km/h"
    private let measuredTrack: MeasuredTrack
    private let dependencies: DependencyManager
    
    
    init(measuredTrack: MeasuredTrack,
         dependencies: DependencyManager) {
        self.dependencies = dependencies
        self.measuredTrack = measuredTrack
    }
    
    var body: some View {
        List {
            Section (header: Text("Measurement Details")){
                baseTrackInfo
            }
            
            Section {
                TrackSpeedStatsView(track: measuredTrack.track, parentTrack: nil)
                    .frame(height: 200)
                topSpeed
            }
            Button(role: .destructive) {
                Task {
                    await dependencies.measuredTrackStorageService
                        .deleteMeasuredTrack(measuredTrack)
                    dependencies.routers[dependencies.tabRouter.selectedTab]?.pop()
                }
            } label: {
                Label("Delete measurement", systemImage: "trash")
                    .foregroundStyle(.red)
            }
        }
        .defaultBackground()
        .navigationTitle(
            Text(
                LocalizedStringKey(measuredTrack.measurement.name),
                tableName: "MeasurementPresets"
            )
        )
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var baseTrackInfo: some View {
        VStack(spacing: 8) {
            Button {
                dependencies.routers[dependencies.tabRouter.selectedTab]?
                    .push(.mapTrackDetail(track: measuredTrack.track, dependencies: dependencies))
            } label: {
                MapSnippetView(mapSnippetCache: dependencies.mapSnippetCache,
                               mapSnapshotGenerator: dependencies.mapSnapshotGenerator,
                               track: measuredTrack.track)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 0)
            }
            mainStat
        }
    }
    
    @ViewBuilder
    private var topSpeed: some View {
        if let speedPoint = measuredTrack.track.points.topSpeedPoint() {
            let unitSpeed = UnitSpeed.byName(speedUnit)
            HStack {
                VStack {
                    let interval = speedPoint.date.timeIntervalSince(measuredTrack.track.startDate)
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
    
    func calculateAverageSpeed() -> CLLocationSpeed? {
        let points = measuredTrack.track.points
        guard !points.isEmpty,
              let stopDate = measuredTrack.track.stopDate else {
            return nil
        }

        // Calculate total distance traveled
        let totalDistance = points.totalDistance()
        
        // Calculate total time (in seconds)
        let totalTime = (stopDate.timeIntervalSince(measuredTrack.track.startDate))
        
        // Guard against zero or near-zero time
        guard totalTime > 0 else {
            return nil
        }

        // Average speed in m/s
        let averageSpeedInMetersPerSecond = totalDistance / totalTime
        
        // Set the average speed (m/s)
        return CLLocationSpeed(averageSpeedInMetersPerSecond)
    }
    
    
    private var mainStat: some View {
        HStack {
            let unitSpeed = UnitSpeed.byName(speedUnit)
            CompactTrackDistanceView(distance: measuredTrack.track.points.totalDistance(),
                                     unit: unitSpeed)
            Spacer()
            if let stopDate = measuredTrack.track.stopDate {
                CompactTrackDurationView(startDate: measuredTrack.track.startDate,
                                         stopDate: stopDate)
            }
            Spacer()
            if let averageSpeed = self.calculateAverageSpeed() {
               CompactTrackAvgSpeedView(speed: averageSpeed,
                                        unit: unitSpeed)
            }
        }
    }
}


#Preview {
    NavigationView {
        MeasuredTrackDetailView(measuredTrack: .init(id: "ee", measurement: .reachingDistance(30, name: "1/8 mile"), track: .filledTrack), dependencies: .mock())
            .navigationBarTitleDisplayMode(.inline)
    }
}
