//
//  DependencyManager.swift
//  DuckRunner
//
//  Created by vladukha on 22.02.2026.
//

import Foundation

final class DependencyManager {
    let locationService: any LocationServiceProtocol
    let storageService: any TrackStorageProtocol
    let mapSnapshotGenerator: any MapSnapshotGeneratorProtocol
    let mapSnippetCache: any TrackMapSnippetCacheProtocol
    let trackReplayCoordinator: any TrackReplayCoordinatorProtocol
    let tabRouter: any TabRouterProtocol
    let cacheFileManager: any CacheFileManagerProtocol
    /// Routers by Tab tags
    let routers: [String: Router]
    
    init(
        locationService: any LocationServiceProtocol,
        storageService: any TrackStorageProtocol,
        mapSnapshotGenerator: any MapSnapshotGeneratorProtocol,
        mapSnippetCache: any TrackMapSnippetCacheProtocol,
        trackReplayCoordinator: any TrackReplayCoordinatorProtocol,
        tabRouter: any TabRouterProtocol,
        cacheFileManager: any CacheFileManagerProtocol,
        routers: [String: Router],
    ) {
        self.locationService = locationService
        self.storageService = storageService
        self.mapSnapshotGenerator = mapSnapshotGenerator
        self.mapSnippetCache = mapSnippetCache
        self.trackReplayCoordinator = trackReplayCoordinator
        self.tabRouter = tabRouter
        self.cacheFileManager = cacheFileManager
        self.routers = routers
    }
}
