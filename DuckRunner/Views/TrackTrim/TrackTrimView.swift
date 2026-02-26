//
//  TrackTrimView.swift
//  DuckRunner
//
//  Created by vladukha on 23.02.2026.
//

import SwiftUI
import AnotherSUIRouter
import MapKit

extension Route where Self == TrackTrimView.RouteBuilder {
    /// View of trimming the track
    static func trackTrim(track: Track,
                            first: TrackPoint,
                            last: TrackPoint,
                            dependencies: DependencyManager) -> TrackTrimView.RouteBuilder {
        TrackTrimView.RouteBuilder(track: track,
                                     first: first,
                                     last: last,
                                     dependencies: dependencies)
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
         let first: TrackPoint
         let last: TrackPoint
         let dependencies: DependencyManager

        func build() -> AnyView {
            AnyView(TrackTrimView(track: track,
                                  first: first,
                                  last: last,
                                  dependencies: dependencies))
        }
    }
    
    @State private var start: TrackPoint
    @State private var stop: TrackPoint
    let track: Track
    
    func trimmedTrack(_ track: [TrackPoint], start: TrackPoint, stop: TrackPoint) -> [TrackPoint] {
        guard let startIndex = track.firstIndex(where: { $0 == start }),
              let stopIndex = track.lastIndex(where: { $0 == stop }),
              startIndex <= stopIndex else {
            return []
        }
        return Array(track[startIndex...stopIndex])
    }
    private let dependencies: DependencyManager
    
    init(track: Track,
         first: TrackPoint,
         last: TrackPoint,
         dependencies: DependencyManager) {
        self.track = track
        self.start = first
        self.stop = last
        self.dependencies = dependencies
    }
    
    var body: some View {
        let trimmedTrack = trimmedTrack(track.points,
                                       start: start,
                                       stop: stop)
        MapView(mode: .free(track)) {
            MapContents.fantomTrack(track)
            MapContents.speedTrack(trimmedTrack)
        }
            .overlay(alignment: .bottom) {
                VStack {
                    if track.points.count !=
                        trimmedTrack.count {
                        HStack {
                            Button {
                                Task {
                                    var track = self.track
                                    track.points = trimmedTrack
                                    track.startDate = trimmedTrack.first?.date ?? Date()
                                    track.stopDate = trimmedTrack.last?.date
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
                                    .font(.title)
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
                                                      points: trimmedTrack,
                                                      startDate: trimmedTrack.first?.date ?? Date(),
                                                      stopDate: trimmedTrack.last?.date,
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
                                    .font(.title)
                                    .bold()
                                    .foregroundStyle(Color.primary)
                                    .padding(8)
                                    .frame(maxWidth: .infinity)
                            }
                            .glassEffect(.regular.tint(.green.opacity(0.5)).interactive(), in: Capsule())
                            .transition(.opacity)
                        }
                    }
                    TrackTrimSlider(points: track.points, start: $start, stop: $stop)
                        .padding()
                        .glassEffect()
                }
                .animation(.bouncy, value: trimmedTrack.count)
            }
    }
}

#Preview {
    TrackTrimView(track: .filledTrack,
                  first: Track.filledTrack.points.first!,
                  last: Track.filledTrack.points.last!,
                  dependencies: .mock())
}
