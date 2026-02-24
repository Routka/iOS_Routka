//
//  DuckRunnerApp.swift
//  DuckRunner
//
//  Created by vladukha on 15.02.2026.
//

import SwiftUI
import SwiftData

@main
struct DuckRunnerApp: App {
    @State var tabRouter: any TabRouterProtocol
    private let dependencies: DependencyManager
    init() {
        self.dependencies = .production(tabs: [
            "History",
                                              ])
        self.tabRouter = dependencies.tabRouter
    }
    
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $tabRouter.selectedTab) {
                
                BaseMapView(dependencies: dependencies)
                .tabItem {
                    Label("Map", systemImage: "map")
                }
                .tag("Map")
                if let router = dependencies.routers["History"] {
                    NavigatableView(router) {
                        TrackHistoryView(dependencies: dependencies)
                    }
                    .tabItem {
                        Label("History", systemImage: "book.pages")
                    }
                    .tag("History")
                }
                SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag("Settings")
            }
            .disclaimerOnce()
        }
    }
}
