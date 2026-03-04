//
//  MockDependencies.swift
//  DuckRunner
//
//  Created by vladukha on 22.02.2026.
//

import Foundation
import Combine
import CoreLocation
import SwiftUI

extension DependencyManager {
    static func mock(locationService: any LocationServiceProtocol = MockLocationService(),
                     storageService: any TrackStorageProtocol = MockStorage(),
                     mapSnapshotGenerator: any MapSnapshotGeneratorProtocol = MockMapSnapshotGenerator(),
                     mapSnippetCache: any TrackMapSnippetCacheProtocol = MockTrackMapSnippetCache(),
                     trackReplayCoordinator: any TrackReplayCoordinatorProtocol = MockTrackReplayCoordinator(),
                     tabRouter: any TabRouterProtocol = MockTabRouter(),
                     cacheFileManager: any CacheFileManagerProtocol = MockCacheFileManager(),
                     measuredTrackStorageService: any MeasuredTrackStorageProtocol = MockMeasuredTrackStorageService(),
                     routers: [String: Router] = [:]
    ) -> Self {
        self.init(locationService: locationService,
                  storageService: storageService,
                  mapSnapshotGenerator: mapSnapshotGenerator,
                  mapSnippetCache: mapSnippetCache,
                  trackReplayCoordinator: trackReplayCoordinator,
                  tabRouter: tabRouter,
                  cacheFileManager: cacheFileManager,
                  measuredTrackStorageService: measuredTrackStorageService,
                  routers: routers)
    }
}

// MARK: - Mock default implementations
extension DependencyManager {
    final class MockMeasuredTrackStorageService: MeasuredTrackStorageProtocol {
        var actionPublisher: PassthroughSubject<MeasuredTrackStorageAction, Never> = .init()
        
        func getMeasuredTracks() async -> [MeasuredTrack] {
            return []
        }
        
        func addMeasuredTrack(_ track: MeasuredTrack) async {
        }
        
        func deleteMeasuredTrack(_ track: MeasuredTrack) async {
        }
    }
    
    final class MockStorage: TrackStorageProtocol {
        func getTrack(by id: String) async -> Track? {
            return nil
        }
        
        func getTracks(withParentID parent: String) async -> [Track] {
            return []
        }
        
        func getTracks(for date: Date) async -> [Track] {
            return []
        }
        
        func getAllTracks() async -> [Track] {
            return []
        }
        
        func addTrack(_ track: Track) async throws {
        }
        
        func deleteTrack(_ track: Track) async {
        }
        
        func updateTrack(_ track: Track) async throws {
        }
        
        var actionPublisher: PassthroughSubject<TrackStorageAction, Never> = .init()
    }
    
    final class MockLocationService: LocationServiceProtocol {
        var authorizationStatus: CurrentValueSubject<CLAuthorizationStatus, Never> = .init(.notDetermined)
        
        func requestLocationAccess() {
            
        }
        
        var location: PassthroughSubject<CLLocation, Never> = .init()
    }
    
    final actor MockCacheFileManager: CacheFileManagerProtocol {
        func removeAllTrackMapCacheFiles() async {
        }
        
        func fileNames(atPath path: String, containing substring: String) -> [String] {
            return []
        }
        
        func fileExists(atPath path: String) -> Bool {
            return false
        }
        
        func contents(atPath path: String) -> Data? {
            return nil
        }
        
        func createFile(atPath path: String, contents data: Data?, attributes attr: [Data.WritingOptions]?) {
        }
        
        func removeItem(atPath path: String) {
        }
    }
    
    @Observable
    final class MockTabRouter: TabRouterProtocol {
        var selectedTab: String = ""
    }
    
    final actor MockTrackReplayCoordinator: TrackReplayCoordinatorProtocol {
        nonisolated
        let selectedTrackPublisher: PassthroughSubject<TrackReplayAction, Never> = .init()
        
        func selectTrackToReplay(_ track: Track) {
            selectedTrackPublisher.send(.select(track))
        }
        
        func deselectReplay() {
            selectedTrackPublisher.send(.deselect)
        }
        init() {
            
        }
    }
    
    final class MockTrackMapSnippetCache: TrackMapSnippetCacheProtocol {
        func removeAllCacheFiles() async {
        }
        
        func invalidateCache(for trackID: String) async {
        }
        
        func getSnippet(for track: Track, size: CGSize) async -> UIImage? {
            return nil
        }
        func cacheSnippet(_ snippet: UIImage, for track: Track, size: CGSize) async {
        }
    }
    
    final class MockMapSnapshotGenerator: MapSnapshotGeneratorProtocol {
        func generateSnapshot(track: Track, size: CGSize) async throws -> UIImage? {
            return nil
        }
    }
}
