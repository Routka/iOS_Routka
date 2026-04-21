//
//  RoutkaApp.swift
//  Routka
//
//  Created by vladukha on 15.02.2026.
//

import SwiftUI
import SwiftData
import vladukhaAlerts
import NeedleFoundation
let appComponent = AppComponent()
public let mainLogger: MainLogger = .init("RoutkaCategory")

nonisolated
class AppComponent: BootstrapComponent {
    @MainActor
    public var routers: [String: Router] {
        shared { ["Tracks": Router()] }
    }
    
    @MainActor
    public var storageService: any TrackStorageProtocol {
        shared { TrackRepository() }
    }
    
    @MainActor
    public var mapSnippetCache: any TrackMapSnippetCacheProtocol {
        shared { TrackMapSnippetCache(fileManager: self.cacheFileManager) }
    }
    
    @MainActor
    public var trackFileService: any TrackFileServiceProtocol {
        shared { TrackFileService(trackStorage: self.storageService) }
    }
    @MainActor
    public var trackReplayCoordinator: any TrackReplayCoordinatorProtocol {
        shared { TrackReplayCoordinator() }
    }
    
    @MainActor
    public var cacheFileManager: any CacheFileManagerProtocol {
        shared { CacheFileManager() }
    }
    
    @MainActor
    public var tabRouter: any TabRouterProtocol {
        shared { TabRouter() }
    }
    
    @MainActor
    public var locationService: any LocationServiceProtocol {
        shared { LocationService() }
    }
    
    #warning("Move lower to TrackTabComponent")
    @MainActor
    public var mapSnapshotGenerator: any MapSnapshotGeneratorProtocol {
        shared { MapSnapshotGenerator() }
    }
    
    @MainActor
    var root: RootComponent {
        RootComponent(parent: self)
    }

}

protocol RootDependency: Dependency {
    var tabRouter: any TabRouterProtocol { get }
    var routers: [String: Router] { get }
}


nonisolated
final class RootComponent: Component<RootDependency> {
    
    @MainActor
    var viewModel: RootViewModel {
        RootViewModel(tabRouter: dependency.tabRouter,
                      routers: dependency.routers,
                      component: self)
    }
    
    @MainActor
    var view: some View {
        RootView(vm: viewModel)
    }
    
    @MainActor
    var trackDetail: TrackDetailComponent {
        TrackDetailComponent(parent: self, track: .filledTrack)
    }
}


@Observable
final class RootViewModel {
    var tabRouter: any TabRouterProtocol
    let routers: [String: Router]
    let alertController: AlertController = .shared
    let component: RootComponent
    
    init(tabRouter: any TabRouterProtocol,
         routers: [String: Router],
         component: RootComponent) {
        self.tabRouter = tabRouter
        self.routers = routers
        self.component = component
    }
    
    var trackDetailView: some View {
        self.component.trackDetail.view
    }
}

struct RootView: View {
    @State private var vm: RootViewModel
    init(vm: RootViewModel) {
        self.vm = vm
    }
    var body: some View {
        TabView(selection: $vm.tabRouter.selectedTab) {
            Tab("Map", systemImage: "map", value: "map") {
                EmptyView()
//                BaseMapView(vm: baseMapViewModel,
//                            dependencies: dependencies)
            }
            if let router = vm.routers["Tracks"] {
                Tab("Tracks", systemImage: "book.pages", value: "Tracks") {
                    NavigatableView(router) {
                        vm.trackDetailView
//                        TracksTabView(vm: tracksTabViewModel, dependencies: dependencies)
                    }
                }
                .accessibilityIdentifier("tracksTab")
            }
        }
    }
}



/// The main app entry point for the Routka application.
@main
struct RoutkaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            appComponent.root.view
        }
    }
    
}
//    @State var tabRouter: any TabRouterProtocol
//    private let alertController: AlertController = .shared
//    private let dependencies: DependencyManager
//    private let baseMapViewModel: BaseMapViewModel
//    private let tracksTabViewModel: TracksTabViewModel
//    private let preferredColorScheme: ColorScheme?
//
//    init() {
//        self.dependencies = .production(tabs: [
//            "Tracks"
//                                              ])
//        self.tabRouter = dependencies.tabRouter
//        self.baseMapViewModel = BaseMapViewModel(dependencies: dependencies)
//        self.tracksTabViewModel = .init(dependencies: dependencies)
//        self.preferredColorScheme = ProcessInfo.processInfo.arguments.contains("UITestingDarkModeEnabled") ? .dark : nil
//    }
//    
//    /// The main scene of the application providing the app's user interface structure.
//    var body: some Scene {
//        WindowGroup {
//            TabView(selection: $tabRouter.selectedTab) {
//                Tab("Map", systemImage: "map", value: "map") {
//                    BaseMapView(vm: baseMapViewModel,
//                                dependencies: dependencies)
//                }
//                if let router = dependencies.routers["Tracks"] {
//                    Tab("Tracks", systemImage: "book.pages", value: "Tracks") {
//                        NavigatableView(router) {
//                            TracksTabView(vm: tracksTabViewModel, dependencies: dependencies)
//                        }
//                    }
//                    .accessibilityIdentifier("tracksTab")
//                }
//            }
//            .disclaimerOnce()
//            .fileManager(managedBy: dependencies)
//            .alertable(alertController,
//                       alignment: .top)
//            .preferredColorScheme(preferredColorScheme)
//        }
//    }
//}
