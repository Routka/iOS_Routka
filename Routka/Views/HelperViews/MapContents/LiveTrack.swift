//
//  LiveTrack.swift
//  Routka
//
//  Created by vladukha on 04.04.2026.
//


import SwiftUI
import MapKit

extension MapContents {
    /// Track polyline with accent colored track
    @MapContentBuilder
    static public func liveTrack(_ track: Track) -> some MapContent {
        MapPolyline(coordinates: track.points.map({$0.position}),
                    contourStyle: .straight)
        .stroke(Color.accentColor,
                style: .init(lineWidth: 4,
                             lineCap: .round,
                             lineJoin: .round))
    }
}

#Preview {
    Map() {
        MapContents.liveTrack(.filledTrack)
    }
}
