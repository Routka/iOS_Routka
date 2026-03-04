//
//  TrackPresetsView.swift
//  DuckRunner
//
//  Created by vladukha on 04.03.2026.
//

import SwiftUI

struct TrackPresetsView: View {
    @Environment(\.presentationMode) var presentationMode
    private var vm: any BaseMapViewModelProtocol
    private let dependencies: DependencyManager
    init(vm: any BaseMapViewModelProtocol,
         dependencies: DependencyManager) {
        self.vm = vm
        self.dependencies = dependencies
    }
    
    @ViewBuilder
    func button(_ text: String, _ image: String, action: @escaping () -> ()) -> some View {
            Button {
                action()
                presentationMode.wrappedValue.dismiss()
            } label: {
                HStack {
                    Image(systemName: image)
                        .foregroundStyle(Color.accentColor)
                        .font(.title)
                    Text(text)
                        .foregroundStyle(Color.primary)
                        .font(.title2)
                    Spacer()
                    Image(systemName: "play.fill")
                        .font(.title2)
                        .padding()
                        .foregroundStyle(Color.primary)
                        .glassEffect(.regular.interactive(),
                                     in: Circle())
                }
                
                .padding(4)
            }
        
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Choose the measurement to record")
                    .font(.largeTitle)
                    .multilineTextAlignment(.leading)
                    .bold()
                    .fixedSize(horizontal: false, vertical: true)
                // 1/2 mile
                button("1/2 mile", "lines.measurement.horizontal.aligned.bottom") {
                    self.vm.startTrack(.reachingDistance(804.672, name: "1/2 mile"))
                }
                Divider()
                // 1/4 mile
                button("1/4 mile", "lines.measurement.horizontal.aligned.bottom") {
                    self.vm.startTrack(.reachingDistance(402.336, name: "1/4 mile"))
                }
                Divider()
                // 1/8 mile
                button("1/8 mile", "lines.measurement.horizontal.aligned.bottom") {
                    self.vm.startTrack(.reachingDistance(201.168, name: "1/8 mile"))
                }
                Divider()
                
                // 0-100 km/h
                button("0-100 km/h",
                       "gauge.open.with.lines.needle.67percent.and.arrowtriangle") {
                    self.vm.startTrack(.reachingSpeed(27.7778, name: "0-100 km/h"))
                }
                Divider()
                // 0-60 km/h
                button("0-60 km/h",
                       "gauge.open.with.lines.needle.67percent.and.arrowtriangle") {
                    self.vm.startTrack(.reachingSpeed(16.6667, name: "0-60 km/h"))
                }
                
            }
            .padding()
        }
        .scrollBounceBehavior(.basedOnSize)
        .presentationDetents([.fraction(0.7)])
        .presentationDragIndicator(.visible)
    }
}

import Combine
import CoreLocation
@Observable
private final class PreviewModel: BaseMapViewModelProtocol {
    
    func isRecordingTrack() -> Bool {
        return true
    }
    
    var mapMode: MapViewMode = .free(.filledTrack)
    
    var trackControlMode: TrackControlMode = .available
    
    var currentSpeed: CLLocationSpeed? = 0
    
    var locationAccess: CLAuthorizationStatus = .authorizedWhenInUse
    
    var trackRecordingService: any TrackRecordingServiceProtocol = TrackRecordingService()
    
    var replayValidator: TrackReplayValidator? = nil
    
    func startTrack(_ mode: RecordingAutoStopPolicy = .manual) {
    }
    
    func stopTrack() async throws {
    }
    
    func deselectReplay() {
    }
    
    func requestLocation() {
    }
}

#Preview {
    Color.red
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            TrackPresetsView(vm: PreviewModel(), dependencies: .mock())
        }
}
