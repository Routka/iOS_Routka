//
//  TrackTrimView.swift
//  Routka
//
//  Created by vladukha on 23.02.2026.
//

import SwiftUI
import SimpleRouter
import MapKit

extension Route where Self == TrackTrimView.RouteBuilder {
    /// View of trimming the track
    static func trackTrim(track: Track,
                            dependencies: DependencyManager) -> TrackTrimView.RouteBuilder {
        TrackTrimView.RouteBuilder(track: track,
                                     dependencies: dependencies)
    }
}

import Combine
@Observable
final class TrackTrimViewModel {
    let track: Track
    var trimmedTrack: Track
    var startIndex: Int {
        didSet {
            self.trimTrack(startPoint: startIndex,
                           stopPoint: self.stopIndex)
//            startIndexPub.send(startIndex)
        }
    }
    var stopIndex: Int {
        didSet {
            self.trimTrack(startPoint: startIndex,
                           stopPoint: self.stopIndex)
//            startIndexPub.send(startIndex)
        }
    }
    let maxCount: Int
    
    private let startIndexPub = PassthroughSubject<Int, Never>()
    private let stopIndexPub = PassthroughSubject<Int, Never>()
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(track: Track) {
        self.track = track
        self.trimmedTrack = track
        self.startIndex = 0
        self.stopIndex = track.points.count - 1
        self.maxCount = track.points.count - 1
        
//        startIndexPub
//            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
//            .sink { newStartIndex in
//                self.trimTrack(startPoint: newStartIndex,
//                               stopPoint: self.stopIndex)
//            }
//            .store(in: &cancellables)
//        stopIndexPub
//            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
//            .sink { newStopIndex in
//                self.trimTrack(startPoint: self.startIndex,
//                          stopPoint: newStopIndex)
//            }
//            .store(in: &cancellables)
    }
    
    private func trimTrack(startPoint: Int, stopPoint: Int) {
        let cut = track.points[startPoint...stopPoint]
        trimmedTrack.points = Array(cut)
    }
    
}

struct TrackTrimView: View {
    struct RouteBuilder: Route {
        static func == (lhs: RouteBuilder, rhs: RouteBuilder) -> Bool {
            lhs.track == rhs.track
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(track)
        }
        
         let track: Track
         let dependencies: DependencyManager

        func build() -> AnyView {
            AnyView(TrackTrimView(track: track,
                                  dependencies: dependencies))
        }
    }
    
    private let dependencies: DependencyManager
    @State private var vm: TrackTrimViewModel
    
    init(track: Track,
         dependencies: DependencyManager) {
        self._vm = .init(initialValue: .init(track: track))
        self.dependencies = dependencies
    }
    
    var body: some View {
        MapView(mode: .free(vm.track), dependencies: dependencies) {
            MapContents.fantomTrack(vm.track)
            MapContents.speedTrack(vm.trimmedTrack)
        }
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
                Task {
                    let track = self.vm.trimmedTrack
                    do {
                        try await dependencies.storageService.updateTrack(track)
                        dependencies.routers[dependencies.tabRouter.selectedTab]?
                            .pop()
                        await dependencies.mapSnippetCache.invalidateCache(for: track.id)
                    } catch {
                        print("Failed saving track", error)
                    }
                }
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
                Task {
                    let NewTrack = Track(id: UUID().uuidString,
                                         points: vm.trimmedTrack.points,
                                      parentID: nil)
                    do {
                        try await dependencies.storageService.addTrack(NewTrack)
                        let router = dependencies.routers[dependencies.tabRouter.selectedTab]
                        router?.popToRoot()
                        try? await Task.sleep(for: .seconds(0.5))
                        router?.push(.trackDetail(track: NewTrack, dependencies: dependencies))
                    } catch {
                        print("Failed saving track", error)
                    }
                }
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

#Preview {
    TrackTrimView(track: .filledTrack,
                  dependencies: .mock())
}
