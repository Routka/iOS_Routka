//
//  TrackDetailView 2.swift
//  Routka
//
//  Created by vladukha on 06.03.2026.
//
import SwiftUI
import CoreLocation
import SimpleRouter
import NeedleFoundation

protocol MeasuredTrackDetail: Dependency {
    var measuredTrackStorageService: any MeasuredTrackStorageProtocol { get }
    var tabRouter: any TabRouterProtocol { get }
    var routers: [String: Router] { get }
}

nonisolated
final class MeasuredTrackDetailComponent: Component<MeasuredTrackDetail> {
    private let measuredTrack: MeasuredTrack
    init(parent: any Scope,
         measuredTrack: MeasuredTrack) {
        self.measuredTrack = measuredTrack
        super.init(parent: parent)
    }
    
    @MainActor
    var view: MeasuredTrackDetailView {
        MeasuredTrackDetailView(measuredTrack: measuredTrack,
                                mapSnippetComponent: mapSnippet,
                                measuredTrackStorageService: dependency.measuredTrackStorageService,
                                tabRouter: dependency.tabRouter,
                                routers: dependency.routers,
                                trackMapComponent: trackMapComponent)
    }
    
    @MainActor
    var mapSnippet: MapSnippetComponent {
        MapSnippetComponent(parent: self, track: measuredTrack.track)
    }
    
    @MainActor
    var trackMapComponent: TrackMapComponent {
        TrackMapComponent(parent: self, track: measuredTrack.track)
    }
    
    @MainActor
    var route: any Route {
        RouteBuilder(component: self)
    }
    
    @MainActor
    struct RouteBuilder: Route {
        static func == (lhs: RouteBuilder, rhs: RouteBuilder) -> Bool {
            lhs.component.measuredTrack == rhs.component.measuredTrack
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(component.measuredTrack)
        }
        
        let component: MeasuredTrackDetailComponent
        
        func build() -> AnyView {
            AnyView(component.view)
        }
    }
}

struct MeasuredTrackDetailView: View {

    /// User preference stored for the speed unit (e.g., km/h or mph).
    @AppStorage("speedunit") var speedUnit: String = "km/h"
    private let measuredTrack: MeasuredTrack
    private let mapSnippetComponent: MapSnippetComponent
    private let measuredTrackStorageService: any MeasuredTrackStorageProtocol
    private let tabRouter: any TabRouterProtocol
    private let routers: [String: Router]
    private let trackMapComponent: TrackMapComponent
    init(measuredTrack: MeasuredTrack,
         mapSnippetComponent: MapSnippetComponent,
         measuredTrackStorageService: any MeasuredTrackStorageProtocol,
         tabRouter: any TabRouterProtocol,
         routers: [String: Router],
         trackMapComponent: TrackMapComponent) {
        self.measuredTrack = measuredTrack
        self.mapSnippetComponent = mapSnippetComponent
        self.measuredTrackStorageService = measuredTrackStorageService
        self.routers = routers
        self.tabRouter = tabRouter
        self.trackMapComponent = trackMapComponent
    }
    
    func delete() {
        Task {
            await measuredTrackStorageService
                .deleteMeasuredTrack(measuredTrack)
            routers[tabRouter.selectedTab]?.pop()
        }
    }
    
    func openDetailMap() {
        let route = self.trackMapComponent.route
        routers[tabRouter.selectedTab]?.push(route)
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
                self.delete()
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
                self.openDetailMap()
            } label: {
                mapSnippetComponent.mapSnippet
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

nonisolated
class MockMeasuredTrackDetailComponent: BootstrapComponent {
    @MainActor
    public var locationService: any LocationServiceProtocol {
        DependencyManager.MockLocationService()
    }
    @MainActor
    public var measuredTrackStorageService: any MeasuredTrackStorageProtocol {
        DependencyManager.MockMeasuredTrackStorageService()
    }
    @MainActor
    public var tabRouter: any TabRouterProtocol {
        DependencyManager.MockTabRouter()
    }
    @MainActor
    public var routers: [String: Router] {
        ["Tracks": Router()]
    }
    @MainActor
    public var mapSnippetCache: any TrackMapSnippetCacheProtocol {
        DependencyManager.MockTrackMapSnippetCache()
    }
    @MainActor
    public var mapSnapshotGenerator: any MapSnapshotGeneratorProtocol {
        MapSnapshotGenerator()
    }
   
   @MainActor
    var measuredTrack: MeasuredTrackDetailComponent {
        MeasuredTrackDetailComponent(parent: self,
                                     measuredTrack: .init(id: "ee",
                                                          measurement: .reachingDistance(30, name: "1/8 mile"),
                                                          track: .filledTrack))
    }
}

#Preview {
    NavigationView {
        let component = MockMeasuredTrackDetailComponent()
        return component.measuredTrack.view
            .navigationBarTitleDisplayMode(.inline)
    }
}
