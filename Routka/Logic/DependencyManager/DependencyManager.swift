//
//  DependencyManager.swift
//  Routka
//
//  Created by vladukha on 22.02.2026.
//

import Foundation

let dependencyManagerLogger = MainLogger("Dependencies")

final class DependencyManager {
    let locationService: any LocationServiceProtocol
    let storageService: any TrackStorageProtocol
    let mapSnapshotGenerator: any MapSnapshotGeneratorProtocol
    let mapSnippetCache: any TrackMapSnippetCacheProtocol
    let trackReplayCoordinator: any TrackReplayCoordinatorProtocol
    let tabRouter: any TabRouterProtocol
    let cacheFileManager: any CacheFileManagerProtocol
    let measuredTrackStorageService: any MeasuredTrackStorageProtocol
    let trackFileService: any TrackFileServiceProtocol
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
        measuredTrackStorageService: any MeasuredTrackStorageProtocol,
        trackFileService: any TrackFileServiceProtocol,
        routers: [String: Router],
    ) {
        self.locationService = locationService
        self.storageService = storageService
        self.mapSnapshotGenerator = mapSnapshotGenerator
        self.mapSnippetCache = mapSnippetCache
        self.trackReplayCoordinator = trackReplayCoordinator
        self.tabRouter = tabRouter
        self.cacheFileManager = cacheFileManager
        self.measuredTrackStorageService = measuredTrackStorageService
        self.trackFileService = trackFileService
        self.routers = routers
        dependencyManagerLogger.log("Initialized dependency manager",
                                    message: """
                                    locationService: \(String(describing: type(of: locationService)))
                                    storageService: \(String(describing: type(of: storageService)))
                                    mapSnapshotGenerator: \(String(describing: type(of: mapSnapshotGenerator)))
                                    mapSnippetCache: \(String(describing: type(of: mapSnippetCache)))
                                    trackReplayCoordinator: \(String(describing: type(of: trackReplayCoordinator)))
                                    tabRouter: \(String(describing: type(of: tabRouter)))
                                    cacheFileManager: \(String(describing: type(of: cacheFileManager)))
                                    measuredTrackStorageService: \(String(describing: type(of: measuredTrackStorageService)))
                                    trackFileService: \(String(describing: type(of: trackFileService)))
                                    routers: \(routers.keys.sorted().joined(separator: ", "))
                                    """,
                                    .info)
    }
}
