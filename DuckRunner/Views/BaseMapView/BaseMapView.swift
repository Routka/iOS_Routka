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
        
        MapWithRenderedTrackInfo(currentTrack:  vm.currentTrack,
                                 replayTrack:   vm.replayTrack,
                                 checkpoints:   vm.checkpoints,
                                 mapMode: vm.mapMode)
            .ignoresSafeArea(.all)
            .overlay(alignment: .top) {
                if let currentSpeed = vm.currentSpeed {
                    SpeedometerView(currentSpeed, displayUnit: unitSpeed)
                        .transition(.opacity)
                }
            }
            .overlay(alignment: .bottom, content: {
                VStack(alignment: .trailing) {
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
                    if let track = vm.currentTrack {
                        TrackLiveInfoView(track: track, unit: unitSpeed)
                    }
                        TrackControlButton(vm: vm)
                            .disabled(vm.isTrackControlAvailable == false)
                            .opacity(vm.isTrackControlAvailable ? 1 : 0.6)
                       
                }
                .padding(10)
                .animation(.default, value: vm.replayTrack != nil)
                
            })
            .animation(.bouncy, value: vm.currentSpeed != nil)
    }
}

import Combine
private final class PreviewModel: BaseMapViewModelProtocol {
    func deselectReplay() {
    }
    
    var mapMode: TrackingMapView.MapViewMode = .bounds(.filledTrack)
    
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
    
    var replayTrack: Track? = .filledTrack
    
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
