//
//  RoutkaApp.swift
//  Routka
//
//  Created by vladukha on 15.02.2026.
//

import SwiftUI
import SwiftData
import vladukhaAlerts

public let mainLogger: MainLogger = .init("RoutkaCategory")

/// The main app entry point for the Routka application.
@main
struct RoutkaApp: App {
    @State var tabRouter: any TabRouterProtocol
    private let alertController: AlertController = .shared
    private let dependencies: DependencyManager
    private let baseMapViewModel: BaseMapViewModel
    private let tracksTabViewModel: TracksTabViewModel
    private let preferredColorScheme: ColorScheme?

    init() {
        self.dependencies = .production(tabs: [
            "Tracks"
                                              ])
        self.tabRouter = dependencies.tabRouter
        self.baseMapViewModel = BaseMapViewModel(dependencies: dependencies)
        self.tracksTabViewModel = .init(dependencies: dependencies)
        self.preferredColorScheme = ProcessInfo.processInfo.arguments.contains("UITestingDarkModeEnabled") ? .dark : nil
    }
    
    /// The main scene of the application providing the app's user interface structure.
    var body: some Scene {
        WindowGroup {
            TabView(selection: $tabRouter.selectedTab) {
                Tab("Map", systemImage: "map", value: "map") {
                    BaseMapView(vm: baseMapViewModel,
                                dependencies: dependencies)
                }
                
//                BaseMapView(vm: baseMapViewModel,
//                            dependencies: dependencies)
//                .tabItem {
//                    Label("Map", systemImage: "map")
//                        .accessibilityIdentifier("map")
//                        .accessibilityAddTraits(.isButton)
//                }
//                .tag("Map")
                if let router = dependencies.routers["Tracks"] {
                    Tab("Tracks", systemImage: "book.pages", value: "Tracks") {
                        NavigatableView(router) {
                            TracksTabView(vm: tracksTabViewModel, dependencies: dependencies)
                        }
                    }
                    .accessibilityIdentifier("tracksTab")
//                    NavigatableView(router) {
//                        TracksTabView(vm: tracksTabViewModel, dependencies: dependencies)
//                    }
//                    .tabItem {
//                        Label("Tracks", systemImage: "book.pages")
//                            .accessibilityIdentifier("tracksTab")
//                            .accessibilityAddTraits(.isButton)
//                    }
//                    .tag("Tracks")
                }
//              
//                SettingsView(dependencies: dependencies)
//                .tabItem {
//                    Label("Settings", systemImage: "gear")
//                }
//                .tag("Settings")
            }
            .disclaimerOnce()
            .fileManager(managedBy: dependencies)
            .alertable(alertController,
                       alignment: .top)
            .preferredColorScheme(preferredColorScheme)
        }
    }
}
