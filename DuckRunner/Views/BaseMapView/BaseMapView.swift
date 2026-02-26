//
//  BaseMapView.swift
//  DuckRunner
//
//  Created by vladukha on 15.02.2026.
//

import SwiftUI
import MapKit


/// Convenience initializer for standard setup with required services.
extension BaseMapView where ViewModel == BaseMapViewModel {
    init(dependencies: DependencyManager) {
        self.init(vm: BaseMapViewModel(dependencies: dependencies))
    }
}

/// View for displaying an interactive map and current tracking information, including speed and live track data.
/// Hosts overlays for live speed and track info, and manages user tracking controls.
struct BaseMapView<ViewModel: BaseMapViewModelProtocol>: View {
    /// The view model providing current track, speed, and control actions for the map.
    @StateObject private var vm: ViewModel
    /// User's preferred unit for speed display (persisted in app storage).
    @AppStorage("speedunit") var speedUnit: String = "km/h"
    
    /// Creates a new map view bound to the provided view model instance.
    init(vm: ViewModel) {
        self._vm = .init(wrappedValue: vm)
    }
    
    
    /// The main interface for map display, overlays, and controls.
    var body: some View {
        let unitSpeed = UnitSpeed.byName(speedUnit)
        MapView(mode: vm.mapMode) {
            UserAnnotation()
            if let replayTrack = vm.replayTrack {
                MapContents.replayTrack(replayTrack)
            }
            if let currentTrack = vm.currentTrack {
                MapContents.speedTrack(currentTrack)
            }
            ForEach(vm.checkpoints, id: \.id) { checkpoint in
                MapContents.checkPoint(checkpoint)
            }
            
            if let startPoint = vm.startReplayCheckpoint?.point,
               vm.currentTrack == nil {
                MapContents.startPoint(startPoint)
            }
            
            if let stopPoint = vm.stopReplayCheckpoint?.point {
                MapContents.stopPoint(stopPoint)
            }
            
        }
        .overlay(alignment: .top) {
            if let currentSpeed = vm.currentSpeed {
                SpeedometerView(currentSpeed, displayUnit: unitSpeed)
                    .transition(.opacity)
            }
        }
        .safeAreaInset(edge: .bottom, content: {
            controls
        })
        .overlay(alignment: .topLeading) {
            replayDeselect
                .padding(5)
        }
        .animation(.bouncy, value: vm.currentSpeed != nil)
        .animation(.default, value: vm.replayTrack != nil)
        .animation(.default, value: vm.locationAccess.isAuthorized())
    }
    
    @ViewBuilder
    private var replayDeselect: some View {
        if vm.replayTrack != nil {
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
    
    private var controls: some View {
        VStack {
            if vm.locationAccess.isAuthorized() {
                if let track = vm.currentTrack {
                    let unitSpeed = UnitSpeed.byName(speedUnit)
                    TrackLiveInfoView(track: track, unit: unitSpeed)
                }
                TrackControlButton(vm: vm)
                    .disabled(vm.isTrackControlAvailable == false)
                    .opacity(vm.isTrackControlAvailable ? 1 : 0.6)
            } else {
                LocationAccessControlView(vm: vm)
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 5)
    }
}

import Combine
private final class PreviewModel: BaseMapViewModelProtocol {
    var startReplayCheckpoint: TrackCheckPoint? = nil
    
    var stopReplayCheckpoint: TrackCheckPoint? = nil
    
    var locationAccess: CLAuthorizationStatus = .denied
    
    func requestLocation() {
        
    }
    
    func deselectReplay() {
        self.replayTrack = nil
    }
    
    var mapMode: MapViewMode = .bounds(.filledTrack)
    
    var checkpoints: [TrackCheckPoint] = {
        let points = Track.filledTrack.points
        let array = [
            points[29],
            points[58],
            points[78]
        ]
        return array.map({TrackCheckPoint(point: $0, distanceThreshold: 50)})
    }()
    
    var isTrackControlAvailable: Bool = true
    
    @Published var replayTrack: Track? = .filledTrack
    
    @Published var currentTrack: Track? = .filledTrack
    
    @Published var currentSpeed: CLLocationSpeed? = 0
    
    func startTrack() {
        self.currentSpeed = 35.553
    }
    
    func stopTrack() {
        self.currentSpeed = nil
    }
    
}

#Preview {
    BaseMapView(vm: PreviewModel())
}
