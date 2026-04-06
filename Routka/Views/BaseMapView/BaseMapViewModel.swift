//
//  BaseMapViewModel.swift
//  Routka
//
//  Created by vladukha on 15.02.2026.
//
import SwiftUI
import Combine
import vladukhaAlerts
import MapKit

enum TrackControlMode {
    case unavailable
    case hidden
    case available
}

/// The main view model responsible for managing map-related features,
/// including track recording, location updates handling, and track replay management.
@Observable
final class BaseMapViewModel: BaseMapViewModelProtocol {
    // MARK: - UI show parameters
    var showStartPoint: Bool {
        trackRecordingService.isRecording != true
    }
    
    var showDeselectReplayButton: Bool {
        replayValidator?.track != nil
    }
    
    var showMeasuringProgress: Bool {
        trackRecordingService.stopPolicy != .manual
    }
    
    var showDismissRecordedTrackButton: Bool {
        trackRecordingService.currentTrack != nil &&
        trackRecordingService.isRecording == false
    }
    
    var showControls: Bool {
        trackControlMode != .hidden
    }
    
    var showMeasureTrackSelectorButton: Bool {
        self.trackRecordingService.isRecording == false
    }
    
    var recordingButtonIsRecording: Bool {
        self.trackRecordingService.isRecording
    }
    
    
    // MARK: - Outside parameters
    
    /// The current mode of the map view.
    let mapMode: MapViewMode = .trackUser
    
    /// The mode indicating the availability and visibility of the track control UI.
    var trackControlMode: TrackControlMode = .available
    
    /// The current speed of the user/device, if available.
    var currentSpeed: CLLocationSpeed? = 0
    
    /// The current authorization status for location access.
    var locationAccess: CLAuthorizationStatus = .notDetermined
    
    /// The service responsible for track recording functionality.
    let trackRecordingService: any TrackRecordingServiceProtocol
    
    private(set) var replayValidator: TrackReplayValidator? = nil
    
    // MARK: - Outside methods
    
    /// Clears the currently recorded track.
    func dismissRecordedTrack() {
        self.trackRecordingService.clearTrack()
    }
    
    /// Starts a new track recording session with the specified auto-stop policy.
    /// - Parameter mode: The auto-stop policy to use when starting the track recording. Defaults to `.manual`.
    func startTrack(_ mode: RecordingAutoStopPolicy = .manual) {
        self.trackRecordingService.startTrack(mode)
        if let currentLocation = self.locationService.lastLocation {
            Task {
                await self.receivedLocationUpdate(currentLocation,
                                                  overrideTimestamp: .now)
            }
        }
    }
    
    /// Stops the current track recording session and attempts to save the recorded track asynchronously.
    /// - Throws: An error if stopping or saving the track fails.
    func stopTrack() async throws {
        try await stopAndSaveTrack()
    }
    
    /// Deselects the currently selected replay track, if any.
    func deselectReplay() {
        self.receiveReplayTrackAction(.deselect)
    }
    
    /// Requests location access permissions from the user.
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
        
        // Ignore empty tracks which did not record anything
        guard track.points.count > 1 else {
            self.trackRecordingService.clearTrack()
            await showEmptyTrackAlert()
            return
        }
        
        if self.replayValidator?.stopReplayCheckpoint?.checkPointPassed == true,
           await (self.replayValidator?.trackCompletionByCheckpoints() ?? 0) >= SettingsService.shared.replayCompletionThreshold {
            track.parentID = self.replayValidator?.track.id
            track.replayMode = .replay
        }
        track.custom_name = generatedTrackName(for: track.startDate)
        
        try await self.trackStorageService.addTrack(track)
    }
    
    private func stopAndSaveAsMeasuredTrack() async throws {
        var track = try self.trackRecordingService.stopTrack()
        track.trackType = .measurement
        let measurementType = self.trackRecordingService.stopPolicy
        
        guard track.points.count > 1 else {
            self.trackRecordingService.clearTrack()
            await showEmptyTrackAlert()
            return
        }
        
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
    
    private func showEmptyTrackAlert() async {
        await AlertController.shared.showAlert(String(localized: "Empty track not created alert"),
                                               icon: .angryWarning,
                                               timeout: 10,
                                               closable: true,
                                               feedback: .warning)
    }

    private func generatedTrackName(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("d MMM")
        let formattedDate = formatter.string(from: date)

        switch hour {
        case 5..<12:
            return String(localized: "Morning route \(formattedDate)",
                          comment: "Generated default name for a track recorded in the morning. Argument is the localized short date.")
        case 12..<17:
            return String(localized: "Afternoon route \(formattedDate)",
                          comment: "Generated default name for a track recorded in the afternoon. Argument is the localized short date.")
        case 17..<22:
            return String(localized: "Evening route \(formattedDate)",
                          comment: "Generated default name for a track recorded in the evening. Argument is the localized short date.")
        default:
            return String(localized: "Night route \(formattedDate)",
                          comment: "Generated default name for a track recorded at night. Argument is the localized short date.")
        }
    }
    
    /// Handles a new location update by processing the location data,
    /// updating the current speed, appending the track position,
    /// and checking replay checkpoints as needed.
    /// - Parameter location: The updated location to process.
    func receivedLocationUpdate(_ location: CLLocation,
                                overrideTimestamp: Date? = nil) async {
        let trackPoint: TrackPoint = .init(position: location.coordinate,
                                           speed: max(0,location.speed),
                                           date: overrideTimestamp ?? location.timestamp)
        self.currentSpeed = max(0,location.speed)
        
        if self.trackRecordingService.isRecording {
            let suggestedAction = try? self.trackRecordingService.appendTrackPosition(trackPoint)
            
            switch suggestedAction {
            case .immediate:
                // Received command to stop immedietly because of AutoStopPolicy
                try? await stopAndSaveAsMeasuredTrack()
            default:
                // Do nothing, continue
                break
            }
        }
        
        await self.checkIfInReplayCheckpoint(location)
        
        await self.replayValidator?.passedPoint(trackPoint)
        
    }
    
    /// Checks if the current location is within any replay checkpoints,
    /// and updates recording state and control modes accordingly.
    /// - Parameter location: The current location to evaluate.
    func checkIfInReplayCheckpoint(_ location: CLLocation) async {
        /*
         if check recordingService not recording
         then we ask replayValidator if we should startRecording, allow start recording or dissallow startRecording
         */
        guard let replayValidator else { return }
        
        // Still not recording
        if self.trackRecordingService.isRecording == false {
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
    
    /// Processes a replay track action such as selection or deselection,
    /// updating the replay validator and track control mode accordingly.
    /// - Parameter action: The replay track action to handle.
    func receiveReplayTrackAction(_ action: TrackReplayAction) {
        switch action {
        case .select(let track):
            _ = try? self.trackRecordingService.stopTrack()
            self.replayValidator = .init(replayingTrack: track,
                                         checkPointInterval: SettingsService.shared.checkpointDistanceInterval)
            self.trackRecordingService.clearTrack()
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
