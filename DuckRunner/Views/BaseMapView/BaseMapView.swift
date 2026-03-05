//
//  BaseMapView.swift
//  DuckRunner
//
//  Created by vladukha on 15.02.2026.
//

import SwiftUI
import MapKit

/// View for displaying an interactive map and current tracking information, including speed and live track data.
/// Hosts overlays for live speed and track info, and manages user tracking controls.
struct BaseMapView: View {
    /// The view model providing current track, speed, and control actions for the map.
    @State private var vm: any BaseMapViewModelProtocol
    /// User's preferred unit for speed display (persisted in app storage).
    @AppStorage("speedunit") var speedUnit: String = "km/h"
    
    @State private var showMeasuredTracksSelector = false
    
    private let dependencies: DependencyManager
    /// Creates a new map view bound to the provided view model instance.
    init(vm: any BaseMapViewModelProtocol,
         dependencies: DependencyManager) {
        self.dependencies = dependencies
        self._vm = State(wrappedValue: vm)
    }
    
    
    /// The main interface for map display, overlays, and controls.
    var body: some View {
        let unitSpeed = UnitSpeed.byName(speedUnit)
        MapView(mode: vm.mapMode, dependencies: dependencies) {
            UserAnnotation()
            if let replayTrack = vm.replayValidator?.track {
                MapContents.replayTrack(replayTrack)
            }
            if let currentTrack = vm.trackRecordingService.currentTrack {
                MapContents.speedTrack(currentTrack)
            }
            let checkPoints = vm.replayValidator?.checkpoints
                .map({$0.value})
            
            ForEach(checkPoints ?? [], id: \.id) { checkpoint in
                MapContents.checkPoint(checkpoint)
            }
            
            if let startPoint = vm.replayValidator?.startReplayCheckpoint?.point,
               vm.trackRecordingService.currentTrack == nil {
                MapContents.startPoint(startPoint)
            }
            
            if let stopPoint = vm.replayValidator?.stopReplayCheckpoint?.point {
                MapContents.stopPoint(stopPoint)
            }
            
        }
        .overlay(alignment: .top) {
            if let currentSpeed = vm.currentSpeed {
                SpeedometerView(currentSpeed, displayUnit: unitSpeed)
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .bottom) {
            controls
            // Moving control out of the way of Apple Maps legal label
            .padding(.bottom, 25)
        }
        .overlay(alignment: .topLeading) {
            replayDeselect
                .padding(5)
        }
        .animation(.bouncy, value: vm.currentSpeed != nil)
        .animation(.bouncy, value: vm.trackRecordingService.currentTrack != nil)
        .animation(.default, value: vm.replayValidator?.track != nil)
        .animation(.default, value: vm.locationAccess.isAuthorized())
        .sheet(isPresented: $showMeasuredTracksSelector) {
            TrackPresetsView(vm: TrackPresetsViewModel(baseMapVM: vm,
                                                       dependencies: dependencies))
        }
    }
    
    @ViewBuilder
    private var replayDeselect: some View {
        if vm.replayValidator?.track != nil {
            Button {
                vm.deselectReplay()
            } label: {
                Text("Stop Replay")
                    .bold()
                    .foregroundStyle(Color.primary)
                    .padding(8)
            }
            .glassEffect(.regular.tint(.accentColor.opacity(0.5)).interactive(), in: Capsule())
            .transition(.opacity)
        }
    }
    
    
    private func measureInfoTag(_ measurement: RecordingAutoStopPolicy) -> some View {
        let progress = vm.trackRecordingService.stopPolicyProgress
        return HStack {
            Image(systemName: measurement.image)
                .foregroundStyle(Color.mint)
            if progress < 1 {
                Text("Measuring")
            }
            Text(measurement.name)
                .bold()
            CircularProgressView(progress: progress)
                .frame(width: 20)
        }
        .animation(.bouncy, value: progress)
    }

    private var controls: some View {
        VStack {
            if vm.locationAccess.isAuthorized() {
                let measurement = vm.trackRecordingService.stopPolicy
                if measurement.type != .manual {
                    let view = measureInfoTag(measurement)
                    // extremely stupid workaround because glass makes colors in CircularProgressView semi transparent
                    view
                        .opacity(.ulpOfOne)
                    .padding(8)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 30))
                    .overlay {
                        view
                    }
                }
                if let track = vm.trackRecordingService.currentTrack {
                    let unitSpeed = UnitSpeed.byName(speedUnit)
                    TrackLiveInfoView(track: track, unit: unitSpeed)
                }
                if vm.trackControlMode != .hidden {
                    HStack {
                        if !vm.isRecordingTrack() {
                            Button {
                                self.showMeasuredTracksSelector.toggle()
                            } label: {
                                Image(systemName: "gauge.with.dots.needle.bottom.50percent.badge.plus")
                                    .font(.title)
                                    .bold()
                                    .shadow(radius: 5)
                                    .foregroundStyle(Color.primary)
                                    .padding(8)
                            }
                            .glassEffect(.clear
                                .interactive(), in: Circle())
                        }
                        TrackControlButton(vm: vm)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .disabled(vm.trackControlMode == .unavailable)
                            .opacity(vm.trackControlMode == .available ? 1 : 0.6)
                    }
                }
                    
            } else {
                LocationAccessControlView(vm: vm)
            }
        }
        .padding(.horizontal, 10)
    }
}

import Combine

@Observable
private final class MockTrackRecorder: TrackRecordingServiceProtocol {
    var stopPolicyProgress: Double = 1
    
    var isRecording: Bool = true
    
    var currentTrack: Track? = .filledTrack
    
    var stopPolicy: RecordingAutoStopPolicy = .reachingDistance(30, name: "30-100mkh")
    
    func clearTrack() {
    }
    
    func appendTrackPosition(_ point: TrackPoint) throws(TrackServiceError) -> SuggestedRecordingAction {
        return .allow
    }
    
    func startTrack(_ stopPolicy: RecordingAutoStopPolicy) {
    }
    
    func stopTrack() throws(TrackServiceError) -> Track {
        return .filledTrack
    }
    
    
}

@Observable
private final class PreviewModel: BaseMapViewModelProtocol {
    func isRecordingTrack() -> Bool {
        return true
    }
    
    var mapMode: MapViewMode = .free(.filledTrack)
    
    var trackControlMode: TrackControlMode = .available
    
    var currentSpeed: CLLocationSpeed? = 0
    
    var locationAccess: CLAuthorizationStatus = .authorizedWhenInUse
    
    var trackRecordingService: any TrackRecordingServiceProtocol = MockTrackRecorder()
    
    var replayValidator: TrackReplayValidator? = nil
    
    func startTrack(_ mode: RecordingAutoStopPolicy) {
    }
    
    func stopTrack() async throws {
    }
    
    func deselectReplay() {
    }
    
    func requestLocation() {
    }
}

#Preview {
    BaseMapView(vm: PreviewModel(), dependencies: .mock())
}
