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
    
    func isRecordingTrack() -> Bool {
        if self.trackRecordingService.isRecording {
            return true
        } else {
            return false
        }
    }
    
    /// Manual track start
    func startTrack(_ mode: RecordingAutoStopPolicy = .manual) {
        self.trackRecordingService.startTrack(mode)
    }
    
    func stopTrack() async throws {
        try await stopAndSaveTrack()
    }
    
    func deselectReplay() {
        self.receiveReplayTrackAction(.deselect)
    }
    
    func requestLocation() {
        self.locationService.requestLocationAccess()
    }
    
    // MARK: - Dependencies
    let locationService: any LocationServiceProtocol
    let trackStorageService: any TrackStorageProtocol
    let measuredTrackStorageService: any MeasuredTrackStorageProtocol
    let trackReplayCoordinator: any TrackReplayCoordinatorProtocol
    
    var cancellables: Set<AnyCancellable> = .init()
    
    // MARK: - Internal logic methods
    
    private func stopAndSaveTrack() async throws {
        var track = try self.trackRecordingService.stopTrack()
        
        if self.replayValidator?.stopReplayCheckpoint?.checkPointPassed == true,
           await (self.replayValidator?.trackCompletionByCheckpoints() ?? 0) >= SettingsService.shared.replayCompletionThreshold {
            track.parentID = self.replayValidator?.track.id
            track.type = .replay
        }
        
        guard track.points.isEmpty == false else { return }
        try await self.trackStorageService.addTrack(track)
    }
    
    private func stopAndSaveAsMeasuredTrack() async throws {
        let track = try self.trackRecordingService.stopTrack()
        let measurementType = self.trackRecordingService.stopPolicy
        
        guard track.points.isEmpty == false else { return }
        
        try await self.trackStorageService.addTrack(track)
        switch measurementType.type {
        case .manual:
            break
        case .reachingSpeed(_):
            await self.measuredTrackStorageService.addMeasuredTrack(.init(id: UUID().uuidString,
                                                                              measurement: measurementType,
                                                                              track: track))
        case .reachingDistance(_):
            await self.measuredTrackStorageService.addMeasuredTrack(.init(id: UUID().uuidString,
                                                                              measurement: measurementType,
                                                                              track: track))
        }
    }
    
    func receivedLocationUpdate(_ location: CLLocation) async {
        let trackPoint: TrackPoint = .init(position: location.coordinate,
                                           speed: max(0,location.speed),
                                           date: location.timestamp)
        self.currentSpeed = max(0,location.speed)
        
        let suggestedAction = try? self.trackRecordingService.appendTrackPosition(trackPoint)
        
        switch suggestedAction {
        case .immediate:
            // Received command to stop immedietly because of AutoStopPolicy
            try? await stopAndSaveAsMeasuredTrack()
        default:
            // Do nothing, continue
            break
        }
        
        await self.checkIfInReplayCheckpoint(location)
        
        await self.replayValidator?.passedPoint(trackPoint)
        
        
        
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
                self.replayValidator?.startValidatingReplay()
                /// Manual recording control since its delegated to replayValidator logic
                self.trackRecordingService.startTrack(.manual)
                // Record this point at which the start occured
                _ = try? self.trackRecordingService.appendTrackPosition(.init(position: location.coordinate,
                                                                     speed: location.speed,
                                                                     date: location.timestamp))
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
                self.replayValidator?.stopValidatingReplay()
                try? await self.stopTrack()
            }
        }
    }
    
    func receiveReplayTrackAction(_ action: TrackReplayAction) {
        switch action {
        case .select(let track):
            _ = try? self.trackRecordingService.stopTrack()
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
        self.trackStorageService = dependencies.storageService
        self.measuredTrackStorageService = dependencies.measuredTrackStorageService
        
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

