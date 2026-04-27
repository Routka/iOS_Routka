//
//  TrackTrimView.swift
//  Routka
//
//  Created by vladukha on 23.02.2026.
//

import SwiftUI
import MapKit

struct TrackTrimView: View {
    
    @State private var vm: any TrackTrimViewModelProtocol
    
    init(vm: any TrackTrimViewModelProtocol) {
        self._vm = .init(wrappedValue: vm)
    }
    
    var body: some View {
        MapView(vm: .init(mode: vm.mapMode,
                          locationService: vm.locationService), content: {
            MapContents.fantomTrack(vm.track)
            MapContents.speedTrack(vm.trimmedTrack)
        })
            .overlay(alignment: .bottom) {
                VStack {
                    if vm.track.points.first != vm.trimmedTrack.points.first ||
                        vm.track.points.last != vm.trimmedTrack.points.last {
                        controls
                    }
                    
                    StartStopSliderView(startIndex: $vm.startIndex,
                                        stopIndex: $vm.stopIndex,
                                        maxIndex: vm.maxCount)
                        .padding()
                        .glassEffect(in: RoundedRectangle(cornerRadius: 40))
                        .padding(.bottom, 25) // apple maps legal padding
                }
                .padding(.horizontal)
            }
    }
    
    @ViewBuilder
    private var controls: some View {
        HStack {
            Button {
                vm.saveCurrent()
            } label: {
                Text("Save")
                    .font(.headline)
                    .bold()
                    .foregroundStyle(Color.primary)
                    .padding(8)
                    .frame(maxWidth: .infinity)
            }
            .glassEffect(.regular.tint(.green.opacity(0.5)).interactive(), in: Capsule())
            .transition(.opacity)
            Button {
                vm.saveAsNewTrack()
            } label: {
                Text("Save As New")
                    .font(.headline)
                    .bold()
                    .foregroundStyle(Color.primary)
                    .padding(8)
                    .frame(maxWidth: .infinity)
            }
            .glassEffect(.regular.tint(.green.opacity(0.5)).interactive(), in: Capsule())
            .transition(.opacity)
        }
    }
}

//#Preview {
//    TrackTrimView(track: .filledTrack,
//                  dependencies: .mock())
//}
