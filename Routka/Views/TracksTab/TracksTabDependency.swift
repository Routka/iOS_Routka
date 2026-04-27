//
//  TracksTabDependency.swift
//  Routka
//
//  Created by vladukha on 22.04.2026.
//

import NeedleFoundation
import Foundation

/// Dependencies needed for TracksTabView and ViewModel
protocol TracksTabDependency: Dependency {
    var storageService: any TrackStorageProtocol { get }
    var measuredTrackStorageService: any MeasuredTrackStorageProtocol { get }
    var tabRouter: any TabRouterProtocol { get }
    var routers: [String: Router] { get }
    var trackFileService: any TrackFileServiceProtocol { get }
    var trackDetailBuilder: any TrackDetailBuilder { get }
}

/// Component that manages dependency and linking between all TracksTab Services
nonisolated
final class TracksTabComponent: Component<TracksTabDependency> {
    
    @MainActor
    var viewModel: any TracksTabViewModelProtocol {
        TracksTabViewModel(storageService: dependency.storageService,
                           measuredTrackStorageService: dependency.measuredTrackStorageService,
                           trackFileService: dependency.trackFileService,
                           routing: routing,
                           componentsFactory: componentsFactory)
    }

    @MainActor
    private var routing: any TracksTabRouting {
        TracksTabNavigator(component: self,
                           tabRouter: dependency.tabRouter,
                           routers: dependency.routers)
    }
    
    @MainActor
    private var componentsFactory: any TracksTabComponentsFactory {
        TracksTabComponentsFactoryImpl(component: self)
    }
    
    @MainActor
    var view: TracksTabView {
        TracksTabView(vm: viewModel)
    }
}

/// Navigator that created child components and resolves navigation using them
private final class TracksTabNavigator: TracksTabRouting {
    private let component: TracksTabComponent
    private let tabRouter: any TabRouterProtocol
    private let routers: [String: Router]

    init(component: TracksTabComponent,
         tabRouter: any TabRouterProtocol,
         routers: [String: Router]) {
        self.component = component
        self.tabRouter = tabRouter
        self.routers = routers
    }

    func openTrack(_ track: Track) {
        let route = component.trackDetailComponent(track: track).route
        routers[tabRouter.selectedTab]?.push(route)
    }
    
    func openMap() {
        tabRouter.selectedTab = "Map"
    }
    
    func openImportedTracks() {
        let route = component.importedTracks.route
        routers[tabRouter.selectedTab]?.push(route)
    }
    
    func openMeasuredTracks() {
        let route = component.measuredTracks.route
        routers[tabRouter.selectedTab]?.push(route)
    }
    
    func openTrackHistory() {
        let route = component.trackHistoryComponent().route
        routers[tabRouter.selectedTab]?.push(route)
    }
    
    func openMeasuredTrack(_ measure: MeasuredTrack) {
        let route = component.measuredtrackDetail(measuredTrack: measure).route
        routers[tabRouter.selectedTab]?.push(route)
    }
}

/// Factory creating components that are needed inside TracksTabView
private final class TracksTabComponentsFactoryImpl: TracksTabComponentsFactory {
    private let component: TracksTabComponent

    init(component: TracksTabComponent) {
        self.component = component
    }
    
    func trackHistoryCell(track: Track, unitSpeed: UnitSpeed) -> TrackHistoryCellComponent {
        component.trackHistoryCell(track: track, unitSpeed: unitSpeed)
    }
}


/// Factory for child components of TracksTab for navigation uses
extension TracksTabComponent {
    @MainActor
    func trackDetailComponent(track: Track) -> TrackDetailComponent {
        dependency.trackDetailBuilder.trackDetail(track)
    }
    
    @MainActor
    func trackHistoryComponent() -> TrackHistoryComponent {
        TrackHistoryComponent(parent: self)
    }
    
    @MainActor
    var importedTracks: ImportedTracksComponent {
        ImportedTracksComponent(parent: self)
    }
    
    @MainActor
    var measuredTracks: MeasuredTracksComponent {
        MeasuredTracksComponent(parent: self)
    }
    
    @MainActor
    func trackHistoryCell(track: Track,
                          unitSpeed: UnitSpeed) -> TrackHistoryCellComponent {
        TrackHistoryCellComponent(parent: self,
                                  track: track,
                                  unitSpeed: unitSpeed)
    }
    
    @MainActor
    func measuredtrackDetail(measuredTrack: MeasuredTrack) -> MeasuredTrackDetailComponent {
        MeasuredTrackDetailComponent(parent: self, measuredTrack: measuredTrack)
    }
}
