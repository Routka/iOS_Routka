//
//  ImportedTracksDependency.swift
//  Routka
//
//  Created by vladukha on 27.04.2026.
//
import Foundation
import NeedleFoundation
import SimpleRouter
import SwiftUI

// MARK: List of Dependencies
protocol ImportedTracksDependency: Dependency {
    var storageService: any TrackStorageProtocol { get }
    var tabRouter: any TabRouterProtocol { get }
    var routers: [String: Router] { get }
    var trackDetailBuilder: any TrackDetailBuilder { get }
    var trackFileService: any TrackFileServiceProtocol { get }
}

// MARK: Main Component Creation
nonisolated
final class ImportedTracksComponent: Component<ImportedTracksDependency> {
    
    private let id: UUID = .init()
    
    @MainActor
    var viewModel: any ImportedTracksListViewModelProtocol {
        ImportedTracksListViewModel(storageService: dependency.storageService,
                                    componentsFactory: componentsFactory,
                                    routing: routing,
                                    trackFileService: dependency.trackFileService)
    }
    
    @MainActor
    private var routing: any ImportedTracksRouting {
        ImportedTracksNavigator(component: self,
                            tabRouter: dependency.tabRouter,
                            routers: dependency.routers)
    }
    
    @MainActor
    private var componentsFactory: any ImportedTracksComponentsFactory {
        ImportedTracksFactoryImpl(component: self)
    }
    
    @MainActor
    var view: ImportedTracksListView {
        ImportedTracksListView(vm: viewModel)
    }
    
    @MainActor
    var route: any Route {
        RouteBuilder(component: self)
    }
    
    @MainActor
    struct RouteBuilder: Route {
        static func == (lhs: RouteBuilder, rhs: RouteBuilder) -> Bool {
            lhs.component.id == rhs.component.id
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(component.id)
        }
        
        let component: ImportedTracksComponent
        
        func build() -> AnyView {
            AnyView(component.view)
        }
    }
}

// MARK: Child Components Factory
/// Factory for creating child components from viewmodel -> component
@MainActor
protocol ImportedTracksComponentsFactory: AnyObject {
    func trackHistoryCell(_ track: Track, _ unitSpeed: UnitSpeed) -> TrackHistoryCellComponent
}

/// Factory creating components that are needed inside TracksTabView
private final class ImportedTracksFactoryImpl: ImportedTracksComponentsFactory {
    private let component: ImportedTracksComponent
    
    init(component: ImportedTracksComponent) {
        self.component = component
    }
    
    func trackHistoryCell(_ track: Track, _ unitSpeed: UnitSpeed) -> TrackHistoryCellComponent {
        component.trackHistoryCell(track, unitSpeed)
    }
}


/// Factory for child components of module for navigation uses
extension ImportedTracksComponent {
    @MainActor
    func trackHistoryCell(_ track: Track, _ unitSpeed: UnitSpeed) -> TrackHistoryCellComponent {
        TrackHistoryCellComponent(parent: self, track: track, unitSpeed: unitSpeed)
    }
    
    @MainActor
    func trackDetail(_ track: Track) -> TrackDetailComponent {
        dependency.trackDetailBuilder.trackDetail(track)
    }
}

// MARK: Navigation Module
/// Navigation connecting layer for viewmodel <-> component
@MainActor
protocol ImportedTracksRouting: AnyObject {
    func openTrack(_ track: Track)
}

/// Navigator that created child components and resolves navigation using them
private final class ImportedTracksNavigator: ImportedTracksRouting {
    private let component: ImportedTracksComponent
    private let tabRouter: any TabRouterProtocol
    private let routers: [String: Router]
    
    init(component: ImportedTracksComponent,
         tabRouter: any TabRouterProtocol,
         routers: [String: Router]) {
        self.component = component
        self.tabRouter = tabRouter
        self.routers = routers
    }
    
    func openTrack(_ track: Track) {
        let route = component.trackDetail(track).route
        routers[tabRouter.selectedTab]?.push(route)
    }
}

