//
//  TrackHistoryDependency.swift
//  Routka
//
//  Created by vladukha on 23.04.2026.
//

import Foundation
import NeedleFoundation
import SimpleRouter
import SwiftUI

protocol TrackHistoryDependency: Dependency {
    var storageService: any TrackStorageProtocol { get }
    var tabRouter: any TabRouterProtocol { get }
    var routers: [String: Router] { get }
}

nonisolated
final class TrackHistoryComponent: Component<TrackHistoryDependency> {
    private let id: UUID = .init()
    
    @MainActor
    var viewModel: any TrackHistoryViewModelProtocol {
        TrackHistoryViewModel(storageService: dependency.storageService,
                              routing: routing,
                              componentsFactory: componentsFactory)
    }
    
    @MainActor
    private var routing: any TrackHistoryRouting {
        TrackHistoryNavigator(component: self,
                           tabRouter: dependency.tabRouter,
                           routers: dependency.routers)
    }
    
    @MainActor
    private var componentsFactory: any TrackHistoryComponentsFactory {
        TrackHistoryComponentsFactoryImpl(component: self)
    }
    
    @MainActor
    var view: TrackHistoryView {
        TrackHistoryView(vm: viewModel)
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
        
        let component: TrackHistoryComponent
        
        func build() -> AnyView {
            AnyView(component.view)
        }
    }
}

/// Factory for creating child components from viewmodel -> component
@MainActor
protocol TrackHistoryComponentsFactory: AnyObject {
    func trackHistoryCell(track: Track, unitSpeed: UnitSpeed) -> TrackHistoryCellComponent
}

/// Factory creating components that are needed inside TracksTabView
private final class TrackHistoryComponentsFactoryImpl: TrackHistoryComponentsFactory {
    private let component: TrackHistoryComponent

    init(component: TrackHistoryComponent) {
        self.component = component
    }
    
    func trackHistoryCell(track: Track, unitSpeed: UnitSpeed) -> TrackHistoryCellComponent {
        component.trackHistoryCell(track: track, unitSpeed: unitSpeed)
    }
}


/// Factory for child components of TracksTab for navigation uses
extension TrackHistoryComponent {
    @MainActor
    func trackDetailComponent(track: Track) -> TrackDetailComponent {
        TrackDetailComponent(parent: self, track: track)
    }
    
    
    @MainActor
    func trackHistoryCell(track: Track,
                          unitSpeed: UnitSpeed) -> TrackHistoryCellComponent {
        TrackHistoryCellComponent(parent: self,
                                  track: track,
                                  unitSpeed: unitSpeed)
    }
}

/// Navigation connecting layer for viewmodel <-> component
@MainActor
protocol TrackHistoryRouting: AnyObject {
    func openTrack(_ track: Track)
}

/// Navigator that created child components and resolves navigation using them
private final class TrackHistoryNavigator: TrackHistoryRouting {
    private let component: TrackHistoryComponent
    private let tabRouter: any TabRouterProtocol
    private let routers: [String: Router]
    
    init(component: TrackHistoryComponent,
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
}
