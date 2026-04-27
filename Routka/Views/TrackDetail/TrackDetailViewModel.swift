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
final class TrackDetailViewModel: TrackDetailViewModelProtocol {
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
    
    /// Average speed of CLLocationSpeed
    var averageSpeed: CLLocationSpeed?
    var parentTrack: Track?
    var children: [Track] = []
    
    /// The track instance whose details are displayed.
    private(set) var track: Track
    private let storageService: any TrackStorageProtocol
    private let trackFileService: any TrackFileServiceProtocol
    private let trackReplayCoordinator: any TrackReplayCoordinatorProtocol
    private var cancellables: Set<AnyCancellable> = []
    private let routing: any TrackDetailRouting
    private let componentsFactory: any TrackDetailComponentsFactory
    /// Initializes the view model with a specific track.
    /// - Parameter track: The track to present.
    init(track: Track,
         storageService: any TrackStorageProtocol,
         trackFileService: any TrackFileServiceProtocol,
         trackReplayCoordinator: any TrackReplayCoordinatorProtocol,
         routing: any TrackDetailRouting,
         componentsFactory: any TrackDetailComponentsFactory) {
        self.track = track
        self.storageService = storageService
        self.trackFileService = trackFileService
        self.trackReplayCoordinator = trackReplayCoordinator
        self.routing = routing
        self.componentsFactory = componentsFactory
        
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
                    routing.popBack()
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
    
    var mapSnippet: MapSnippetComponent {
        self.componentsFactory.trackMapSnippet(track)
    }
    
    func openOriginalRoute() {
        guard let parentTrack else { return }
        routing.openTrack(parentTrack)
        
    }
    
    func openChildTrack(_ child: Track) {
        routing.openTrack(child)
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
        routing.openTrackMap(track)
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
        routing.openMap()
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
