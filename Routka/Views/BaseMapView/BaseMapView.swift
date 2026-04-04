//
//  BaseMapView.swift
//  Routka
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
                MapContents.liveTrack(currentTrack)
            }
            let checkPoints = vm.replayValidator?.checkpoints
                .map({$0.value})
            
            ForEach(checkPoints ?? [], id: \.id) { checkpoint in
                MapContents.checkPoint(checkpoint)
            }
            
            if let startPoint = vm.replayValidator?.startReplayCheckpoint?.point,
               vm.showStartPoint {
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
        .zIndex(1)
        .overlay(alignment: .bottom) {
            bottomBar
                .padding(.horizontal, 10)
            // Moving control out of the way of Apple Maps legal label
                .padding(.bottom, 25)
                .animation(.default, value: vm.locationAccess.isAuthorized())
        }
        .overlay(alignment: .topLeading) {
            replayDeselect
                .padding(5)
        }
        .animation(.bouncy, value: vm.currentSpeed != nil)
        .animation(.bouncy, value: vm.trackRecordingService.currentTrack != nil)
        .animation(.default, value: vm.replayValidator?.track != nil)
        .sheet(isPresented: $showMeasuredTracksSelector) {
            TrackPresetsView(vm: TrackPresetsViewModel(baseMapVM: vm,
                                                       dependencies: dependencies))
        }
    }
    
    @ViewBuilder
    private var replayDeselect: some View {
        if vm.showDeselectReplayButton {
            Button {
                vm.deselectReplay()
            } label: {
                HStack(spacing: 2) {
                    Image(systemName: "xmark")
                    Text("Stop Replay")
                }
                .bold()
                .foregroundStyle(Color.white)
                .padding(8)
            }
            .glassEffect(.clear.tint(.red.opacity(0.8)).interactive(), in: Capsule())
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
    
    @ViewBuilder
    private var bottomBar: some View {
        if vm.locationAccess.isAuthorized() {
            controls
        } else {
            LocationAccessControlView(vm: vm)
        }
    }
    
    private var controls: some View {
        VStack {
            HStack {
                if vm.showMeasuringProgress {
                    measuringProgress
                }
                if vm.showDismissRecordedTrackButton {
                    dismissRecordedTrackButton
                }
            }
            .animation(.bouncy, value: vm.showMeasuringProgress)
            .animation(.bouncy, value: vm.showDismissRecordedTrackButton)
            if let track = vm.trackRecordingService.currentTrack {
                let unitSpeed = UnitSpeed.byName(speedUnit)
                TrackLiveInfoView(track: track, unit: unitSpeed)
            }
            if vm.showControls {
                HStack {
                    if vm.showMeasureTrackSelectorButton {
                        measuredTracksSelector
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading)
                                    .combined(with: .opacity),
                                removal: .move(edge: .leading)
                                    .combined(with: .opacity)
                            ))
                            .zIndex(1)
                    }
                    startStopButton
                }
                .animation(.bouncy, value: vm.showMeasureTrackSelectorButton)
                .zIndex(2)
            }
        }
        .padding(.horizontal, 10)
    }
    
    private var measuringProgress: some View {
        let measurement = vm.trackRecordingService.stopPolicy
        let view = measureInfoTag(measurement)
        return view
            .opacity(.ulpOfOne)
            .padding(10)
            .glassEffect(in: Capsule())
            .overlay {
                // extremely stupid workaround because glass makes colors in CircularProgressView semi transparent
                view
            }
            .transition(.move(edge: .leading)
                .combined(with: .opacity))
    }
    
    private var dismissRecordedTrackButton: some View {
        Button {
            vm.dismissRecordedTrack()
        } label: {
            Text("Dismiss track statistics")
                .lineLimit(1)
                .font(.headline)
                .padding(10)
                .padding(.horizontal)
            
        }
        .glassEffect(.regular
            .interactive(),
                     in: Capsule())
        .transition(.move(edge: .trailing)
            .combined(with: .opacity))
    }
    
    private var measuredTracksSelector: some View {
        Button {
            self.showMeasuredTracksSelector.toggle()
        } label: {
            Image(systemName: "gauge.with.dots.needle.bottom.50percent.badge.plus")
                .font(.title)
                .bold()
                .shadow(radius: 5)
                .symbolRenderingMode(.multicolor)
                .foregroundStyle(Color.primary)
                .padding(7)
        }
        .glassEffect(.clear
            .interactive(), in: Circle())
    }
    
    private var startStopButton: some View {
        TrackControlButton(buttonType: vm.recordingButtonIsRecording ?
            .stop : .start) {
                Task {
                    if vm.recordingButtonIsRecording {
                        try? await vm.stopTrack()
                    } else {
                        vm.startTrack(.manual)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .disabled(vm.trackControlMode == .unavailable)
            .opacity(vm.trackControlMode == .available ? 1 : 0.6)
    }
}
