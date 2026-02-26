//
//  BaseMapViewModel.swift
//  DuckRunner
//
//  Created by vladukha on 15.02.2026.
//
import SwiftUI
import Combine
import MapKit


final class BaseMapViewModel: BaseMapViewModelProtocol, LocationAccessViewModelProtocol, TrackControllerProtocol {
    // MARK: - Outside parameters
    let mapMode: MapViewMode = .trackUser
    @Published var isTrackControlAvailable: Bool = true
    
    @Published var currentTrack: Track? = nil
    
    @Published var currentSpeed: CLLocationSpeed? = 0
    
    @Published var replayTrack: Track? = nil
    @Published var checkpoints: [TrackCheckPoint] = []
    
    @Published var locationAccess: CLAuthorizationStatus = .notDetermined
    
    @Published var startReplayCheckpoint: TrackCheckPoint?
    @Published var stopReplayCheckpoint: TrackCheckPoint?
    
    // MARK: - Outside methods
    func startTrack() {
        self.trackService.startTrack(at: .now)
        
        // Prevent the device from sleeping during track recording
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func stopTrack() async throws {
        var track = try self.trackService.stopTrack(at: .now)
        // Re-enable the idle timer after stopping the track
        UIApplication.shared.isIdleTimerDisabled = false
        
        if let completion = await self.replayValidator?.trackCompletionByCheckpoints(),
           completion >= SettingsService.shared.replayCompletionThreshold {
            track.parentID = self.replayTrack?.id
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
    let trackService: any LiveTrackServiceProtocol
    let locationService: any LocationServiceProtocol
    let storageService: any TrackStorageProtocol
    let trackReplayCoordinator: any TrackReplayCoordinatorProtocol
    
    // MARK: - Internal variables
    
    var replayValidator: TrackReplayValidator? = nil
    
    var cancellables: Set<AnyCancellable> = .init()
    
    // MARK: - Internal logic methods
    func receivedLocationUpdate(_ location: CLLocation) async {
        let trackPoint: TrackPoint = .init(position: location.coordinate,
                                           speed: max(0,location.speed),
                                           date: .now)
        self.currentSpeed = max(0,location.speed)
        
        try? self.trackService.appendTrackPosition(trackPoint)
        
        
        await self.checkIfInReplayCheckpoint(location)
        // if we haven't recording the track, we dont try to validate the replay
        if currentTrack != nil {
            await self.replayValidator?.passedPoint(trackPoint)
        }
        guard let checkpoints = await self.replayValidator?.checkpoints.map({$0.value})
            .sorted(by: {$0.point.date < $1.point.date}) else { return }
        
        await MainActor.run {
            self.checkpoints = checkpoints
        }
        
    }
    
    /// Reacting if we are in stop or start checkpoints
    func checkIfInReplayCheckpoint(_ location: CLLocation) async {
        guard let replayTrack else { return }
        print("VM: Received location and checking for checkpoint")
        // Still not recording
        if currentTrack == nil {
            print("VM: Track not recording")
            switch replayTrack.type {
            case .classical:
                // If replaying classical track
                print("VM: is classical track")
                // in startPoint
                if startReplayCheckpoint?.isPointInCheckpoint(location.coordinate, printA: true) == true,
                    // if speed < 1 m/s we can allow to start track
                    location.speed < 1 {
                    print("VM: inside and speed is low \(location.speed)")
                    if !self.isTrackControlAvailable {
                        self.startReplayCheckpoint?.setCheckpointPassing(to: true)
                        self.isTrackControlAvailable = true
                    }
                } else {
                    print("VM: not inside or speed to big \(location.speed)")
                    // if speed is higher or we are outside start zone - disable availability to start track
                    if self.isTrackControlAvailable {
                        self.startReplayCheckpoint?.setCheckpointPassing(to: false)
                        self.isTrackControlAvailable = false
                    }
                }
                
            case .speedtrap:
                print("VM: is speedtrap")
                // If replaying speedtrap
                // if we get in startPoint = autostart no matter
                if startReplayCheckpoint?.isPointInCheckpoint(location.coordinate) == true {
                    self.startReplayCheckpoint?.setCheckpointPassing(to: true)
                    self.isTrackControlAvailable = true
                    self.startTrack()
                }
            }
        } else {
            // Already recording
            print("VM: track is recording")
            // If in stop zone - autostop in any track type
            if  self.stopReplayCheckpoint?.checkPointPassed == false,
                stopReplayCheckpoint?.isPointInCheckpoint(location.coordinate) == true {
                self.stopReplayCheckpoint?.setCheckpointPassing(to: true)
                self.isTrackControlAvailable = true
                try? await self.stopTrack()
            }
        }
    }
    
    func receiveReplayTrackAction(_ action: TrackReplayAction) {
        switch action {
        case .select(let track):
            self.currentTrack = nil
            self.replayTrack = track
            self.replayValidator = .init(replayingTrack: track,
                                         checkPointInterval: SettingsService.shared.checkpointDistanceInterval)
            self.isTrackControlAvailable = false
            if let firstPoint = replayTrack?.points.first {
                let checkpoint = TrackCheckPoint(point: firstPoint,
                                                 distanceThreshold: SettingsService.shared.checkpointDistanceActivateThreshold)
                self.startReplayCheckpoint = checkpoint
            }
            if let lastPoint = replayTrack?.points.last {
                let checkpoint = TrackCheckPoint(point: lastPoint,
                                                 distanceThreshold: SettingsService.shared.checkpointDistanceActivateThreshold)
                self.stopReplayCheckpoint = checkpoint
            }
            Task {
                if let checkpoints = await self.replayValidator?.checkpoints.map({$0.value})
                    .sorted(by: {$0.point.date < $1.point.date}) {
                    await MainActor.run {
                        self.checkpoints = checkpoints
                    }
                }
            }
        case .deselect:
            self.replayTrack = nil
            self.replayValidator = nil
            self.isTrackControlAvailable = true
            self.stopReplayCheckpoint = nil
            self.startReplayCheckpoint = nil
            self.checkpoints = []
        }
    }
    
    func receiveCurrentTrack(_ track: Track?) {
        self.currentTrack = track
    }
    
    // MARK: - Init
    init(dependencies: DependencyManager) {
        self.trackReplayCoordinator = dependencies.trackReplayCoordinator
        self.trackService = dependencies.trackService
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
        
        self.trackService
            .currentTrack
            .sink { [weak self] new in
                Task {
                    self?.receiveCurrentTrack(new)
                }
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

