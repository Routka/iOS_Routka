//
//  TrackDetailViewModel.swift
//  Routka
//
//  Created by vladukha on 16.03.2026.
//


import SwiftUI
import MapKit
import Combine
import SimpleRouter
import NeedleFoundation

/// View model responsible for managing and providing detailed track data 
/// for presentation in the TrackDetailView.
@Observable
final class TrackDetailViewModel {
    var showReplayButton: Bool {
        track.parentID == nil
    }
    var showEditSection: Bool {
        track.trackType != .import
    }
    var showDeleteTrackButton: Bool {
        self.children.isEmpty
    }
    var showReplaysSection: Bool {
        !children.isEmpty
    }
    var showExportButton: Bool {
        track.trackType != .import &&
        track.replayMode != .replay
    }
    var showModeEditButton: Bool {
        track.replayMode != .replay
    }
    var showTrimButton: Bool {
        track.parentID == nil &&
        children.isEmpty
    }
    
    let mapSnippetComponent: MapSnippetComponent
    
    
    /// Average speed of CLLocationSpeed
    var averageSpeed: CLLocationSpeed?
    var parentTrack: Track?
    var children: [Track] = []
    
    /// The track instance whose details are displayed.
    private(set) var track: Track
    private let storageService: any TrackStorageProtocol
    private let tabRouter: any TabRouterProtocol
    private let routers: [String: Router]
    private let trackFileService: any TrackFileServiceProtocol
    private let trackReplayCoordinator: any TrackReplayCoordinatorProtocol
    private weak let component: TrackDetailComponent?
    private var cancellables: Set<AnyCancellable> = []
    
    /// Initializes the view model with a specific track.
    /// - Parameter track: The track to present.
    init(track: Track,
         storageService: any TrackStorageProtocol,
         routers: [String: Router],
         tabRouter: any TabRouterProtocol,
         trackFileService: any TrackFileServiceProtocol,
         trackReplayCoordinator: any TrackReplayCoordinatorProtocol,
         component: TrackDetailComponent) {
        self.track = track
        self.storageService = storageService
        self.tabRouter = tabRouter
        self.routers = routers
        self.trackFileService = trackFileService
        self.trackReplayCoordinator = trackReplayCoordinator
        self.component = component
        mapSnippetComponent = component.mapSnippet
        
        self.storageService.actionPublisher
            .sink { [weak self] action in
                self?.receiveAction(action)
            }
            .store(in: &cancellables)
        Task {
            if let parentID = track.parentID,
               let parent = await storageService.getTrack(by: parentID){
                await MainActor.run {
                    self.parentTrack = parent
                }
            } else {
                let children = await storageService.getTracks(withParentID: track.id, ofType: .record)
                await MainActor.run {
                    self.children = children
                }
            }
        }
    }
    
    /// Handles updates from the storage (track creation, deletion, or update) to maintain the correct tracks list.
    private func receiveAction(_ action: TrackStorageAction) {
        withAnimation {
            switch action {
            case .deleted(let track):
                if track.id == self.track.id {
                   routers[tabRouter.selectedTab]?
                        .pop()
                }
                self.children.removeAll(where: {$0.id == track.id})
            case .updated(let track):
                if track.id == self.track.id {
                    self.track = track
                }
                if let indexOfChild = self.children.firstIndex(where: {$0.id == track.id}) {
                    self.children[indexOfChild] = track
                }
            case .created(let track):
                if track.parentID == self.track.id {
                    self.children.append(track)
                }
            }
        }
    }
    
    func openOriginalRoute() {
        guard let parentTrack else { return }
#warning("Missing track navigation logic")
//            dependencies.routers[dependencies.tabRouter.selectedTab]?.push(.trackDetail(track: parentTrack, dependencies: dependencies))
        
    }
    
    func openChildTrack(_ child: Track) {
#warning("Missing track navigation logic")
//        routers[tabRouter.selectedTab]?.push(.trackDetail(track: track, dependencies: dependencies))
    }
    
    func exportTrack() {
        trackFileService.exportTrack(track)
    }
    
    func deleteTrack() {
        Task {
            await storageService.deleteTrack(track)
        }
    }
    
    func openTrackMap() {
        guard let component else { return }
        let trackMap = component.trackMapComponent.route
        routers[tabRouter.selectedTab]?
            .push(trackMap)
    }
    
    func openTrackTrim() {
#warning("Missing track navigation logic")
//        routers[tabRouter.selectedTab]?
//            .push(.trackTrim(track: vm.track,
//                             dependencies: dependencies))
    }
    
    func replayTrack() {
        Task {
            await trackReplayCoordinator.selectTrackToReplay(track)
        }
        tabRouter.selectedTab = "map"
    }
    
    func updateTrackType(to type: ReplayMode) async {
        self.track.replayMode = type
        try? await storageService.updateTrack(track)
    }
    
    func calculateAverageSpeed() {
        let points = track.points
        guard !points.isEmpty,
        let stopDate = track.stopDate else {
            return
        }

        // Calculate total distance traveled
        let totalDistance = points.totalDistance()
        
        // Calculate total time (in seconds)
        let totalTime = (stopDate.timeIntervalSince(track.startDate))
        
        // Guard against zero or near-zero time
        guard totalTime > 0 else {
            return
        }

        // Average speed in m/s
        let averageSpeedInMetersPerSecond = totalDistance / totalTime
        
        // Set the average speed (m/s)
        self.averageSpeed = CLLocationSpeed(averageSpeedInMetersPerSecond)
    }
    
    
}
