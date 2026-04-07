//
//  ReleaseDependencies.swift
//  Routka
//
//  Created by vladukha on 22.02.2026.
//

import Foundation

extension DependencyManager {
    static public func production(tabs: [String] = []) -> DependencyManager {
        dependencyManagerLogger.log("Creating production dependencies",
                                    message: "tabs: \(tabs.joined(separator: ", "))",
                                    .info)
        let locationService = LocationService()
        let storageService = TrackRepository()
        let mapSnapshotGenerator = MapSnapshotGenerator()
        let cacheFileManager = CacheFileManager()
        let mapSnippetCache = TrackMapSnippetCache(fileManager: cacheFileManager)
        let trackReplayCoordinator = TrackReplayCoordinator()
        let tabRouter = TabRouter()
        let measuredTrackStorageService = MeasuredTrackRepository()
        let routers = Dictionary(uniqueKeysWithValues: tabs.map({($0, Router())}))
        let trackFileService = TrackFileService(trackStorage: storageService)
        dependencyManagerLogger.log("Production dependencies created",
                                    message: "routerCount: \(routers.count)",
                                    .info)
        return .init(locationService: locationService,
                     storageService: storageService,
                     mapSnapshotGenerator: mapSnapshotGenerator,
                     mapSnippetCache: mapSnippetCache,
                     trackReplayCoordinator:trackReplayCoordinator,
                     tabRouter: tabRouter,
                     cacheFileManager: cacheFileManager,
                     measuredTrackStorageService: measuredTrackStorageService,
                     trackFileService: trackFileService,
                     routers: routers)
    }
}
