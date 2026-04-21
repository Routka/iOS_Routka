//
//  Router.swift
//  Routka
//
//  Created by vladukha on 24.02.2026.
//

import Foundation
import Combine
import SimpleRouter

let routerLogger = MainLogger("Router")

/// Class to control navigation

public final class Router: RouterProtocol {
    @Published public var path: [AnyRoute] = []

    public func push<R: Route>(_ route: R) {
        path.append(AnyRoute(route))
        routerLogger.log("Pushed route",
                         message: "route: \(String(describing: type(of: route))), depth: \(path.count)",
                         .info)
    }

    public func pop() {
        guard path.isEmpty == false else {
            routerLogger.log("Pop ignored", message: "Navigation stack is already empty", .warning)
            return
        }
        path.removeLast()
        routerLogger.log("Popped route", message: "depth: \(path.count)", .info)
    }

    public func popToRoot() {
        guard path.isEmpty == false else {
            routerLogger.log("Pop to root ignored", message: "Navigation stack is already empty", .warning)
            return
        }
        path.removeAll()
        routerLogger.log("Popped to root", .info)
    }
}
