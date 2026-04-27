//
//  TrackDetailDependency.swift
//  Routka
//
//  Created by vladukha on 23.04.2026.
//

import SimpleRouter
import NeedleFoundation
import SwiftUI

// MARK: - Dependencies
protocol TrackDetailDependency: Dependency {
    var storageService: any TrackStorageProtocol { get }
    var tabRouter: any TabRouterProtocol { get }
    var routers: [String: Router] { get }
    var trackFileService: any TrackFileServiceProtocol { get }
    var trackReplayCoordinator: any TrackReplayCoordinatorProtocol { get }
    var trackDetailBuilder: any TrackDetailBuilder { get }
}

// MARK: - Main Component
nonisolated final class TrackDetailComponent: Component<TrackDetailDependency> {
    private let track: Track
    
    init(parent: Scope, track: Track) {
        self.track = track
        super.init(parent: parent)
    }
    
    var mapSnippet: MapSnippetComponent {
        MapSnippetComponent(parent: self, track: track)
    }
    
    @MainActor
    var viewModel: TrackDetailViewModel {
        TrackDetailViewModel(track: track,
                             storageService: dependency.storageService,
                             trackFileService: dependency.trackFileService,
                             trackReplayCoordinator: dependency.trackReplayCoordinator,
                             routing: routing,
                             componentsFactory: componentsFactory)
    }
    
    @MainActor
    var view: TrackDetailView {
        TrackDetailView(vm: viewModel)
    }
    
    @MainActor
    var routing: any TrackDetailRouting {
        TrackDetailNavigator(component: self,
                             tabRouter: dependency.tabRouter,
                             routers: dependency.routers)
    }
    
    @MainActor
    var componentsFactory: any TrackDetailComponentsFactory {
        TrackDetailComponentsFactoryImpl(component: self)
    }
    
    @MainActor
    var route: any Route {
        RouteBuilder(component: self)
    }
    
    @MainActor
    struct RouteBuilder: Route {
        static func == (lhs: RouteBuilder, rhs: RouteBuilder) -> Bool {
            lhs.component.track == rhs.component.track
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(component.track)
        }
        
        let component: TrackDetailComponent

        func build() -> AnyView {
            AnyView(component.view)
        }
    }
    
}

// MARK: - Components Factory layer
protocol TrackDetailComponentsFactory {
    func trackMapSnippet(_ track: Track) -> MapSnippetComponent
}

final class TrackDetailComponentsFactoryImpl: TrackDetailComponentsFactory {
    private let component: TrackDetailComponent
    
    init(component: TrackDetailComponent){
        self.component = component
    }
    
    func trackMapSnippet(_ track: Track) -> MapSnippetComponent {
        component.mapSnippet
    }
    
    
}

// MARK: - Navigation layer
protocol TrackDetailRouting: AnyObject {
    func openTrack(_ track: Track)
    func openTrackMap(_ track: Track)
    func popBack()
    func openMap()
    func openTrackTrim(_ track: Track)
}

final class TrackDetailNavigator: TrackDetailRouting {
    private let component: TrackDetailComponent
    private let tabRouter: any TabRouterProtocol
    private let routers: [String: Router]
    
    init(component: TrackDetailComponent,
         tabRouter: any TabRouterProtocol,
         routers: [String: Router]) {
        self.component = component
        self.tabRouter = tabRouter
        self.routers = routers
    }
    
    func openTrack(_ track: Track) {
        let route = component.trackDetail(track).route
        routers[tabRouter.selectedTab]?
            .push(route)
    }
    
    func openTrackMap(_ track: Track) {
        let route = component.trackMap(track).route
        routers[tabRouter.selectedTab]?
            .push(route)
    }
    
    func popBack() {
        routers[tabRouter.selectedTab]?
            .pop()
    }
    
    func openMap() {
        tabRouter.selectedTab = "map"
    }
    
    func openTrackTrim(_ track: Track) {
        let route = component.trackTrim(track).route
        routers[tabRouter.selectedTab]?
            .push(route)
    }
}

// MARK: - Components creation
extension TrackDetailComponent {
    @MainActor
    func trackDetail(_ track: Track) -> TrackDetailComponent {
        dependency.trackDetailBuilder.trackDetail(track)
    }
    
    @MainActor
    func trackMap(_ track: Track) -> TrackMapComponent {
        TrackMapComponent(parent: self, track: track)
    }
    
    @MainActor
    func trackTrim(_ track: Track) -> TrackTrimComponent {
        TrackTrimComponent(parent: self, track: track)
    }
}
