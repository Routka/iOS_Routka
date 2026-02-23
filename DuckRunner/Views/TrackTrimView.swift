//
//  TrackTrimView.swift
//  DuckRunner
//
//  Created by vladukha on 23.02.2026.
//

import SwiftUI

struct TrackTrimView: View {
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
    
    init(track: Track,
         dependencies: DependencyManager) {
        self.track = track
        self.start = track.points.first!
        self.stop = track.points.last!
    }
    var body: some View {
        TrackingMapView(overlays: [
            FantomTrackOverlay(track: track.points),
            SpeedTrackOverlay(track: trimmedTrack(track.points,
                                                  start: start,
                                                  stop: stop))
                                  ],
                        mapMode: .bounds(track))
        .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                TrackTrimSlider(points: track.points, start: $start, stop: $stop)
                    .padding()
                    .glassEffect()
            }
    }
}

#Preview {
    TrackTrimView(track: .filledTrack, dependencies: .mock())
}
