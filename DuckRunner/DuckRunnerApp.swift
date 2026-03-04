//
//  DuckRunnerApp.swift
//  DuckRunner
//
//  Created by vladukha on 15.02.2026.
//

import SwiftUI
import SwiftData
//internal import MapKit

@main
struct DuckRunnerApp: App {
    @State var tabRouter: any TabRouterProtocol
    private let dependencies: DependencyManager
    private let baseMapViewModel: BaseMapViewModel
    private let trackHistoryViewModel: TrackHistoryViewModel
    private let measurementsViewModel: any MeasuredTrackListViewModelProtocol
    init() {
        self.dependencies = .production(tabs: [
            "History",
            "Measurements"
                                              ])
        self.tabRouter = dependencies.tabRouter
        self.baseMapViewModel = BaseMapViewModel(dependencies: dependencies)
        self.trackHistoryViewModel = TrackHistoryViewModel(dependencies: dependencies)
        self.measurementsViewModel = MeasuredTrackListViewModel(dependencies: dependencies)
    }
    
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $tabRouter.selectedTab) {
                
                BaseMapView(vm: baseMapViewModel,
                            dependencies: dependencies)
                .tabItem {
                    Label("Map", systemImage: "map")
                }
                .tag("Map")
                if let router = dependencies.routers["History"] {
                    NavigatableView(router) {
                        TrackHistoryView(vm: trackHistoryViewModel,
                                         dependencies: dependencies)
                    }
                    .tabItem {
                        Label("History", systemImage: "book.pages")
                    }
                    .tag("History")
                }
                if let router = dependencies.routers["Measurements"] {
                    NavigatableView(router) {
                        MeasuredTrackListView(vm: measurementsViewModel,
                                              dependencies: dependencies)
                    }
                    .tabItem {
                        Label("Measurements", systemImage: "book.pages")
                    }
                    .tag("Measurements")
                }
                SettingsView(dependencies: dependencies)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag("Settings")
            }
            .disclaimerOnce()
        }
    }
}
