//
//  BaseMapViewModel.swift
//  DuckRunner
//
//  Created by vladukha on 15.02.2026.
//
import SwiftUI
import Combine
import MapKit

enum TrackControlMode {
    case unavailable
    case hidden
    case available
}

@Observable
final class BaseMapViewModel: BaseMapViewModelProtocol {
    
    // MARK: - Outside parameters
    let mapMode: MapViewMode = .trackUser
    var trackControlMode: TrackControlMode = .available
    var currentSpeed: CLLocationSpeed? = 0
    var locationAccess: CLAuthorizationStatus = .notDetermined
    let trackRecordingService: any TrackRecordingServiceProtocol
    private(set) var replayValidator: TrackReplayValidator? = nil
    
    // MARK: - Outside methods
    
    func isReplayingTrack() -> Bool {
        if let track = self.trackRecordingService.currentTrack,
           track.stopDate == nil {
            return true
        } else {
            return false
        }
    }
    func startTrack() {
        self.trackRecordingService.startTrack(at: .now)
    }
    
    func stopTrack() async throws {
        var track = try self.trackRecordingService.stopTrack(at: .now)
        
        if self.replayValidator?.stopReplayCheckpoint?.checkPointPassed == true {
            track.parentID = self.replayValidator?.track.id
        }
        
        guard track.points.isEmpty == false else { return }
        try? await self.storageService.addTrack(track)
    }
    
    func deselectReplay() {
        self.receiveReplayTrackAction(.deselect)
    }
    
    func requestLocation() {
        self.locationService.requestLocationAccess()
    }
    
    // MARK: - Dependencies
    let locationService: any LocationServiceProtocol
    let storageService: any TrackStorageProtocol
    let trackReplayCoordinator: any TrackReplayCoordinatorProtocol
    
    
    
    var cancellables: Set<AnyCancellable> = .init()
    
    // MARK: - Internal logic methods
    func receivedLocationUpdate(_ location: CLLocation) async {
        let trackPoint: TrackPoint = .init(position: location.coordinate,
                                           speed: max(0,location.speed),
                                           date: .now)
        self.currentSpeed = max(0,location.speed)
        
        try? self.trackRecordingService.appendTrackPosition(trackPoint)
        
        
        await self.checkIfInReplayCheckpoint(location)
        
        await self.replayValidator?.passedPoint(trackPoint)
        
        if self.replayValidator?.startReplayCheckpoint?.checkPointPassed == true,
        self.trackRecordingService.currentTrack == nil {
            self.startTrack()
        }
        
        if self.replayValidator?.stopReplayCheckpoint?.checkPointPassed == true {
            try? await self.stopTrack()
        }
        
        
        
    }
    
    /// Reacting if we are in stop or start checkpoints
    func checkIfInReplayCheckpoint(_ location: CLLocation) async {
        /*
         if check recordingService not recording
         then we ask replayValidator if we should startRecording, allow start recording or dissallow startRecording
         */
        guard let replayValidator else { return }
        
        // Still not recording
        if self.trackRecordingService.currentTrack == nil {
            switch replayValidator.suggestedStartRecording(location) {
            case .allow:
                self.trackControlMode = .available
            case .forbid:
                self.trackControlMode = .unavailable
            case .immediate:
                self.trackControlMode = .available
                self.startTrack()
            }
            
        } else {
            // Already recording
            // If in stop zone - autostop in any track type
            switch replayValidator.suggestedStopRecording(location) {
            case .allow:
                self.trackControlMode = .available
            case .forbid:
                self.trackControlMode = .unavailable
            case .immediate:
                self.trackControlMode = .available
                try? await self.stopTrack()
            }
        }
    }
    
    func receiveReplayTrackAction(_ action: TrackReplayAction) {
        switch action {
        case .select(let track):
            _ = try? self.trackRecordingService.stopTrack(at: .now)
            self.replayValidator = .init(replayingTrack: track,
                                         checkPointInterval: SettingsService.shared.checkpointDistanceInterval)
            
            self.trackControlMode = .unavailable
            
        case .deselect:
            self.replayValidator = nil
            self.trackControlMode = .available
        }
    }
    
    
    // MARK: - Init
    init(dependencies: DependencyManager, trackRecordingService: any TrackRecordingServiceProtocol = TrackRecordingService()) {
        self.trackReplayCoordinator = dependencies.trackReplayCoordinator
        self.trackRecordingService = trackRecordingService
        self.locationService = dependencies.locationService
        self.storageService = dependencies.storageService
        
        self.trackReplayCoordinator
            .selectedTrackPublisher
            .receive(on: RunLoop.main)
            .sink {[weak self] action in
                self?.receiveReplayTrackAction(action)
            }
            .store(in: &cancellables)
        
        self.locationService
            .authorizationStatus
            .sink { [weak self] status in
                self?.locationAccess = status
            }
            .store(in: &cancellables)
        
        self.locationService.location
            .receive(on: RunLoop.main)
            .sink { [weak self] location in
                Task {
                    await self?.receivedLocationUpdate(location)
                }
            }
            .store(in: &cancellables)
    }
    
}

