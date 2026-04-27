//
//  MeasuredTracksDependency.swift
//  Routka
//
//  Created by vladukha on 27.04.2026.
//
import Foundation
import NeedleFoundation
import SimpleRouter
import SwiftUI

// MARK: List of Dependencies
protocol MeasuredTracksDependency: Dependency {
    var measuredTrackStorageService: any MeasuredTrackStorageProtocol { get }
    var tabRouter: any TabRouterProtocol { get }
    var routers: [String: Router] { get }
}

// MARK: Main Component Creation
nonisolated
final class MeasuredTracksComponent: Component<MeasuredTracksDependency> {
    
    private let id: UUID = .init()
    
    @MainActor
    var viewModel: any MeasuredTrackListViewModelProtocol {
        MeasuredTrackListViewModel(measuredTrackStorageService: dependency.measuredTrackStorageService,
                                   routing: routing)
    }
    
    @MainActor
    private var routing: any MeasuredTracksRouting {
        MeasuredTracksNavigator(component: self,
                            tabRouter: dependency.tabRouter,
                            routers: dependency.routers)
    }
    
    @MainActor
    var view: MeasuredTrackListView {
        MeasuredTrackListView(vm: viewModel)
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
        
        let component: MeasuredTracksComponent
        
        func build() -> AnyView {
            AnyView(component.view)
        }
    }
}


/// Factory for child components of module for navigation uses
extension MeasuredTracksComponent {
    @MainActor
    func trackDetail(_ measuredTrack: MeasuredTrack) -> MeasuredTrackDetailComponent {
        MeasuredTrackDetailComponent(parent: self, measuredTrack: measuredTrack)
    }
}

// MARK: Navigation Module
/// Navigation connecting layer for viewmodel <-> component
@MainActor
protocol MeasuredTracksRouting: AnyObject {
    func openTrack(_ measuredTrack: MeasuredTrack)
}

/// Navigator that created child components and resolves navigation using them
private final class MeasuredTracksNavigator: MeasuredTracksRouting {
    private let component: MeasuredTracksComponent
    private let tabRouter: any TabRouterProtocol
    private let routers: [String: Router]
    
    init(component: MeasuredTracksComponent,
         tabRouter: any TabRouterProtocol,
         routers: [String: Router]) {
        self.component = component
        self.tabRouter = tabRouter
        self.routers = routers
    }
    
    func openTrack(_ measuredTrack: MeasuredTrack) {
        let route = component.trackDetail(measuredTrack).route
        routers[tabRouter.selectedTab]?.push(route)
    }
}

