//
//  MapView.swift
//  DuckRunner
//
//  Created by vladukha on 26.02.2026.
//

import SwiftUI
import MapKit

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
    
    var mapPosition: MapCameraPosition
    var bounds: MapCameraBounds? = nil
    init(mode: MapViewMode) {
        self.mode = mode
        switch mode {
        case .trackUser:
            self.mapPosition = .userLocation(followsHeading: true, fallback: .automatic)
            self.interactionModes = .all
            self.bounds = nil
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
    
}

struct MapView<Content: MapContent>: View {
    private let content: () -> Content
    @State private var vm: MapViewModel
    
    init(mode: MapViewMode,
         @MapContentBuilder content: @escaping () -> Content) {
        self.content = content
        self._vm = .init(initialValue: .init(mode: mode))
    }
    
    
    var body: some View {
        VStack {
            Map(position: $vm.mapPosition,
                bounds: vm.bounds,
                interactionModes: vm.interactionModes,
                content: content)
            .onMapCameraChange(frequency: .continuous) { context in
                self.vm.cameraPosition = context.region.center
            }
//            .mapControlVisibility(.hidden)
            .mapControls({
                MapCompass()
                    
            })
            .safeAreaInset(edge: .top) {
                followButton
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal)
                    .padding(.top)
            }
            
//            .mapControlVisibility(.)
//            .overlay(alignment: .topTrailing) {
//                followButton
//            }
        }
    }
    
    @ViewBuilder
    private var followButton: some View {
        let tracking = ((!vm.mapPosition.followsUserHeading ||
                         !vm.mapPosition.followsUserLocation) &&
                         vm.mode == .trackUser)
            Button {
                withAnimation {
                    self.vm.mapPosition = .userLocation(followsHeading: true, fallback: .automatic)
                }
            } label: {
                Image(systemName: tracking ? "location.north.line" : "location.north.line.fill")
                    .resizable()
                    .scaledToFit()
                    
                    .padding()
                    .glassEffect(.regular, in: Circle())
                    .frame(width: 45)
            }
            .opacity(
                vm.mode == .trackUser ? 1 : 0
            )
            .animation(.bouncy, value: tracking)
        
    }
}

#Preview {
    MapView(mode: .trackUser) {
        UserAnnotation()
        MapContents.speedTrack(.filledTrack)
        MapContents.fantomTrack(.filledTrack)
    }
}
