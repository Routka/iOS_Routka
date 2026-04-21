//
//  MapView.swift
//  Routka
//
//  Created by vladukha on 26.02.2026.
//

import SwiftUI
import MapKit
import Combine
import NeedleFoundation

enum MapViewMode: Equatable {
    case trackUser
    case bounds(Track)
    /// Like bounds which moves map to the track but you can move it freely
    case free(Track)
}

@Observable
final class MapViewModel {
    
    let mode: MapViewMode
    var cameraPosition: CLLocationCoordinate2D?
    let interactionModes: MapInteractionModes
    
    var isMovingMap: Bool = false
    var mapPosition: MapCameraPosition
    var bounds: MapCameraBounds? = nil
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(mode: MapViewMode,
         locationService: any LocationServiceProtocol) {
        self.mode = mode
        switch mode {
        case .trackUser:
            self.mapPosition = .userLocation(followsHeading: true, fallback: .automatic)
            self.interactionModes = .all
            self.bounds = nil
            locationService
                .location
                .sink { newLocation in
                    self.receivedLocationUpdate(newLocation)
                }
                .store(in: &cancellables)
            Task {
                try? await Task.sleep(for: .seconds(0.1))
                // reposition because after map loading it looses heading follow
                self.mapPosition = .userLocation(followsHeading: true, fallback: .automatic)
            }
        case .bounds(let track):
            let region = track.points.regionOfATrack()
            self.mapPosition = .region(region)
            self.interactionModes = []
            self.bounds = nil
        case .free(let track):
            let region = track.points.regionOfATrack()
            self.mapPosition = .region(region)
            self.interactionModes = .all
            self.bounds = .init(centerCoordinateBounds: region)
        }
    }
    
    //https://github.com/vladukhaDog/Routka/issues/24
    //https://github.com/vladukhaDog/Routka/issues/23#issuecomment-3959911829
    private func receivedLocationUpdate(_ newLocation: CLLocation) {
        guard case .trackUser = mode,
        (!self.mapPosition.followsUserHeading || !self.mapPosition.followsUserLocation),
        !isMovingMap else {
            return
        }
        withAnimation(.easeOut) {
            self.mapPosition = .userLocation(followsHeading: true, fallback: .automatic)
        }
    }
    
}

struct MapView<Content: MapContent>: View {
    private let content: Content
    @State private var vm: MapViewModel
    
    init(vm: MapViewModel,
         @MapContentBuilder content: @escaping () -> Content) {
        self.content = content()
        self._vm = .init(initialValue: vm)
    }
    
    @Namespace var mapScope
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(position: $vm.mapPosition,
                bounds: vm.bounds,
                interactionModes: .all,
                scope: mapScope,
                content: {
                content
            })
            .mapStyle(.standard(elevation: .realistic))
            .onMapCameraChange(frequency: .onEnd, {
                self.vm.isMovingMap = false
            })
            .onMapCameraChange(frequency: .continuous) { context in
                self.vm.cameraPosition = context.region.center
                if self.vm.mapPosition.positionedByUser {
                    self.vm.isMovingMap = true
                }
            }
            .mapControls {
                // SPECIFICALLY EMPTY CONTROLS
                // on 26.2 compass behaves weirdly and stops rotating
            }
            VStack {
                MapPitchToggle(scope: mapScope)
                    .mapControlVisibility(.visible)
                    .glassEffect(.regular.interactive(), in: Circle())
                MapCompass(scope: mapScope)
                    .mapControlVisibility(.visible)
                followButton
            }
            .padding()
            
        }
        .mapScope(mapScope)
    }
    
    @ViewBuilder
    private var followButton: some View {
        let tracking = ((!vm.mapPosition.followsUserHeading ||
                         !vm.mapPosition.followsUserLocation) &&
                        vm.mode == .trackUser)
        if vm.mode == .trackUser {
            Button {
                withAnimation {
                    self.vm.mapPosition = .userLocation(followsHeading: true, fallback: .automatic)
                }
            } label: {
                Image(systemName: tracking ? "location.north.line" : "location.north.line.fill")
                    .resizable()
                    .scaledToFit()
                
                    .padding()
                    .glassEffect(.regular.interactive(), in: Circle())
                    .frame(width: 45)
            }
            .animation(.bouncy, value: tracking)
        }
    }
}

#warning("fix preview")
//#Preview {
//    MapView(mode: .trackUser, dependencies: .mock()) {
//        UserAnnotation()
//        MapContents.speedTrack(.filledTrack)
//        MapContents.fantomTrack(.filledTrack)
//    }
//}
