//
//  ReleaseDependencies.swift
//  DuckRunner
//
//  Created by vladukha on 22.02.2026.
//

import Foundation

extension DependencyManager {
    static public func production(tabs: [String] = []) -> DependencyManager {
        let trackService = TrackRecordingService()
        let locationService = LocationService()
        let storageService = TrackRepository()
        let mapSnapshotGenerator = MapSnapshotGenerator()
        let cacheFileManager = CacheFileManager()
        let mapSnippetCache = TrackMapSnippetCache(fileManager: cacheFileManager)
        let trackReplayCoordinator = TrackReplayCoordinator()
        let tabRouter = TabRouter()
        let routers = Dictionary(uniqueKeysWithValues: tabs.map({($0, Router())}))
        
        return .init(locationService: locationService,
                     storageService: storageService,
                     mapSnapshotGenerator: mapSnapshotGenerator,
                     mapSnippetCache: mapSnippetCache,
                     trackReplayCoordinator:trackReplayCoordinator,
                     tabRouter: tabRouter,
                     cacheFileManager: cacheFileManager,
                     routers: routers)
    }
}
