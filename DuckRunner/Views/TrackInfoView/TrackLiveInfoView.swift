//
//  TrackInfoView.swift
//  DuckRunner
//
//  Created by vladukha on 15.02.2026.
//

import SwiftUI
import Combine
internal import _LocationEssentials

/// Widget that displays Track info which is being recorded
struct TrackLiveInfoView: View {
    let track: Track
    private let unitSpeed: UnitSpeed
    init(track: Track, unit: UnitSpeed) {
        self.track = track
        self.unitSpeed = unit
    }
    
    var body: some View {
        EqualFillHStack {
            TrackTimeView(startDate: track.startDate,
                          stopDate: track.stopDate)
            let speed = track.points.topSpeed() ?? 0
            TrackTopSpeedView(speed,
                              displayUnit: unitSpeed)
            let distance = track.points.totalDistance()
            TrackDistanceView(distance: distance,
                              unit: unitSpeed.unitLength)
        }
        .overlay(alignment: .topTrailing, content: {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(Color.green.opacity(0.7))
                .opacity(track.parentID == nil ? 0 : 1)
        })
        .padding()
        .frame(maxWidth: .infinity)
        .glassEffect(in: RoundedRectangle(cornerRadius: 30))
        
    }
    
}

#Preview {
    var track = Track.filledTrack
    track.parentID = "123"
    return ZStack {
        Color.cyan.opacity(0.4)
        VStack {
            TrackLiveInfoView(track: .filledTrack, unit: .kilometersPerHour)
            TrackLiveInfoView(track: track, unit: .kilometersPerHour)
        }
    }
}
