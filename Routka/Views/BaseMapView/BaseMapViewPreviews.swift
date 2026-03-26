//
//  BaseMapViewPreviews.swift
//  Routka
//
//  Created by vladukha on 26.03.2026.
//
import CoreLocation
import SwiftUI

fileprivate enum PreviewState: String, CaseIterable {
    case readyToRecord
    case unknownAuthorization
    case currentyRecordingClean
    case currentlyRecordingMeasurement
    case recordedMeasurement
}

#Preview(PreviewState.readyToRecord.rawValue) {
    BaseMapView(vm: PreviewModel(.readyToRecord), dependencies: .mock())
}

#Preview(PreviewState.unknownAuthorization.rawValue) {
    BaseMapView(vm: PreviewModel(.unknownAuthorization), dependencies: .mock())
}

#Preview(PreviewState.currentyRecordingClean.rawValue) {
    BaseMapView(vm: PreviewModel(.currentyRecordingClean), dependencies: .mock())
}

#Preview(PreviewState.currentlyRecordingMeasurement.rawValue) {
    BaseMapView(vm: PreviewModel(.currentlyRecordingMeasurement), dependencies: .mock())
}

#Preview(PreviewState.recordedMeasurement.rawValue) {
    BaseMapView(vm: PreviewModel(.recordedMeasurement), dependencies: .mock())
}


@Observable
private final class MockTrackRecorder: TrackRecordingServiceProtocol {
    var stopPolicyProgress: Double = 1
    
    var isRecording: Bool = false
    
    var currentTrack: Track? = nil
    
    var stopPolicy: RecordingAutoStopPolicy = .reachingDistance(30, name: "30-100mkh")
    
    func clearTrack() {
        self.currentTrack = nil
        self.isRecording = false
        self.stopPolicy = .manual
        self.stopPolicyProgress = 0.0
    }
    
    func appendTrackPosition(_ point: TrackPoint) throws(TrackServiceError) -> SuggestedRecordingAction {
        return .allow
    }
    
    func startTrack(_ stopPolicy: RecordingAutoStopPolicy) {
        isRecording = true
        self.stopPolicy = stopPolicy
        self.currentTrack = .filledTrack
    }
    
    func stopTrack() throws(TrackServiceError) -> Track {
        isRecording = false
        return .filledTrack
    }
    
    
}

@Observable
private final class PreviewModel: BaseMapViewModelProtocol {
    var showStartPoint: Bool = true
    var showDeselectReplayButton: Bool = true
    var showMeasuringProgress: Bool = true
    var showDismissRecordedTrackButton: Bool = true
    var showControls: Bool = true
    var showMeasureTrackSelectorButton: Bool = true
    var recordingButtonIsRecording = true
    
    func dismissRecordedTrack() {
        showDismissRecordedTrackButton = false
        trackRecordingService.clearTrack()
        showMeasuringProgress = false
    }
    
    var mapMode: MapViewMode = .free(.filledTrack)
    
    var trackControlMode: TrackControlMode = .available
    
    var currentSpeed: CLLocationSpeed? = 0
    
    var locationAccess: CLAuthorizationStatus = .authorizedWhenInUse
    
    var trackRecordingService: any TrackRecordingServiceProtocol {
        self._trackRecordingService
    }
    var _trackRecordingService: MockTrackRecorder = .init()
    
    var replayValidator: TrackReplayValidator? = .init(replayingTrack: .filledTrack, checkPointInterval: 20)
    
    func startTrack(_ mode: RecordingAutoStopPolicy) {
        self.recordingButtonIsRecording.toggle()
    }
    
    func stopTrack() async throws {
        self.recordingButtonIsRecording.toggle()
        showDismissRecordedTrackButton = true
    }
    
    func deselectReplay() {
    }
    
    func requestLocation() {
    }
    
    init(_ state: PreviewState) {
        switch state {
        case .readyToRecord:
            self.mapMode = .trackUser
            self.currentSpeed = 25
            self.locationAccess = .authorizedWhenInUse
            self.replayValidator = nil
            self.showDeselectReplayButton = false
            self.showMeasuringProgress = false
            self.showDismissRecordedTrackButton = false
            self.showControls = true
            self.showMeasureTrackSelectorButton = true
            self.recordingButtonIsRecording = false
        case .unknownAuthorization:
            self.mapMode = .trackUser
            self.currentSpeed = 25
            self.locationAccess = .notDetermined
            self.replayValidator = nil
            self.showDeselectReplayButton = false
            self.showMeasuringProgress = false
            self.showDismissRecordedTrackButton = false
            self.showControls = false
            self.showMeasureTrackSelectorButton = true
            self.recordingButtonIsRecording = false
        case .currentyRecordingClean:
            self.mapMode = .trackUser
            self.currentSpeed = 25
            self.locationAccess = .authorizedWhenInUse
            self.replayValidator = nil
            self.showDeselectReplayButton = false
            self.showMeasuringProgress = false
            self.showDismissRecordedTrackButton = false
            self.showControls = true
            self.showMeasureTrackSelectorButton = false
            self.recordingButtonIsRecording = true
            self.trackRecordingService.startTrack(.manual)
        case .currentlyRecordingMeasurement:
            self.mapMode = .trackUser
            self.currentSpeed = 25
            self.locationAccess = .authorizedWhenInUse
            self.replayValidator = nil
            self.showDeselectReplayButton = false
            self.showMeasuringProgress = true
            self.showDismissRecordedTrackButton = false
            self.showControls = true
            self.showMeasureTrackSelectorButton = false
            self.recordingButtonIsRecording = true
            self._trackRecordingService.startTrack(.reachingSpeed(84, name: "0-100kmh"))
            self._trackRecordingService.stopPolicyProgress = 0.3
        case .recordedMeasurement:
            self.mapMode = .trackUser
            self.currentSpeed = 25
            self.locationAccess = .authorizedWhenInUse
            self.replayValidator = nil
            self.showDeselectReplayButton = false
            self.showMeasuringProgress = true
            self.showDismissRecordedTrackButton = true
            self.showControls = true
            self.showMeasureTrackSelectorButton = false
            self.recordingButtonIsRecording = false
            self.trackRecordingService.startTrack(.reachingSpeed(84, name: "0-100kmh"))
        }
    }
}

