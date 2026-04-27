//
//  TrackTrimDependency.swift
//  Routka
//
//  Created by vladukha on 27.04.2026.
//

import Foundation
import NeedleFoundation
import SimpleRouter
import SwiftUI

// MARK: List of Dependencies
protocol TrackTrimDependency: Dependency {
    var tabRouter: any TabRouterProtocol { get }
    var routers: [String: Router] { get }
    var trackDetailBuilder: any TrackDetailBuilder { get }
    var storageService: any TrackStorageProtocol { get }
    var locationService: any LocationServiceProtocol { get }
    var mapSnippetCache: any TrackMapSnippetCacheProtocol { get }
}

// MARK: Main Component Creation
nonisolated
final class TrackTrimComponent: Component<TrackTrimDependency> {
    
    private let track: Track
    
    init(parent: Scope, track: Track) {
        self.track = track
        super.init(parent: parent)
    }
    
    @MainActor
    var viewModel: TrackTrimViewModel {
        TrackTrimViewModel(track: track,
                           storageService: dependency.storageService,
                           routing: routing,
                           locationService: dependency.locationService,
                           mapSnippetCache: dependency.mapSnippetCache)
    }
    
    @MainActor
    private var routing: any TrackTrimRouting {
        TrackTrimNavigator(component: self,
                            tabRouter: dependency.tabRouter,
                            routers: dependency.routers)
    }
    
    @MainActor
    var view: TrackTrimView {
        TrackTrimView(vm: viewModel)
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
        
        let component: TrackTrimComponent
        
        func build() -> AnyView {
            AnyView(component.view)
        }
    }
}



/// Factory for child components of module for navigation uses
extension TrackTrimComponent {
    @MainActor
    func trackDetail(_ track: Track) -> TrackDetailComponent {
        dependency.trackDetailBuilder.trackDetail(track)
    }
}

// MARK: Navigation Module
/// Navigation connecting layer for viewmodel <-> component
@MainActor
protocol TrackTrimRouting: AnyObject {
    func openNewTrack(_ track: Track) async
    func pop()
}

/// Navigator that created child components and resolves navigation using them
private final class TrackTrimNavigator: TrackTrimRouting {
    private let component: TrackTrimComponent
    private let tabRouter: any TabRouterProtocol
    private let routers: [String: Router]
    
    init(component: TrackTrimComponent,
         tabRouter: any TabRouterProtocol,
         routers: [String: Router]) {
        self.component = component
        self.tabRouter = tabRouter
        self.routers = routers
    }
    
    func openNewTrack(_ track: Track) async {
        let route = component.trackDetail(track).route
        let router = routers[tabRouter.selectedTab]
        router?.popToRoot()
        try? await Task.sleep(for: .seconds(0.5))
        router?.push(route)
    }
    
    func pop() {
        routers[tabRouter.selectedTab]?.pop()
    }
}

