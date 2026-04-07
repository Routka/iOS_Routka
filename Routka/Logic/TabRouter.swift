//
//  TabRouter.swift
//  Routka
//
//  Created by vladukha on 20.02.2026.
//

import Foundation

let tabRouterLogger = MainLogger("TabRouter")

protocol TabRouterProtocol: AnyObject, Observable{
    var selectedTab: String { get set }
}

@Observable
final class TabRouter: TabRouterProtocol {
    var selectedTab: String = "map" {
        didSet {
            tabRouterLogger.log("Changed selected tab",
                                message: "from: \(oldValue), to: \(selectedTab)",
                                .info)
        }
    }
}
