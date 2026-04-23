//
//  TrackHistoryCellView.swift
//  Routka
//
//  Created by vladukha on 16.02.2026.
//

import SwiftUI


/// View Cell of a Track in history list
struct TrackHistoryCellView: View {
    let track: Track
    let unit: UnitSpeed
    let mapSnippetComponent: MapSnippetComponent
    /// Initializes the history view with the given view model.
    init(track: Track,
         unit: UnitSpeed,
         mapSnippetComponent: MapSnippetComponent) {
        self.track = track
        self.unit = unit
        self.mapSnippetComponent = mapSnippetComponent
    }
    
    var body: some View {
        VStack() {
            header
            mapSnippet
            HStack {
                CompactTrackDistanceView(distance: track.points.totalDistance(),
                                         unit: unit)
                Spacer()
                if let stopDate = track.stopDate {
                    CompactTrackDurationView(startDate: track.startDate,
                                             stopDate: stopDate)
                }
                Spacer()
                if let speed = track.points.topSpeed() {
                    CompactTrackTopSpeedView(speed: speed,
                                             unit: unit)
                }
            }
            
        }
        .foregroundStyle(Color.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(in: RoundedRectangle(cornerRadius: 15))
    }

    @ViewBuilder
    private var header: some View {
        if let customName = track.custom_name {
            HStack {
                Text(customName)
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.leading)
                Spacer()
            }
        } else {
            HStack {
                Text(track.startDate.toString(style: .medium))
                    .font(.title2)
                    .bold()
                Spacer()
            }
            Text(track.startDate.toString(format: "EEE HH:mm"))
                .font(.caption)
                .fontWeight(.semibold)
                .opacity(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var mapSnippet: some View {
        mapSnippetComponent.mapSnippet
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 0)
            
    }
}


#Preview {
    ZStack {
//        Color.cyan.opacity(0.3)
        let component = TrackHistoryCellMockComponentProvider()
        VStack {
            
            component.trackCell(track: .filledTrack, unit: .kilometersPerHour).view
            component.trackCell(track: .filledTrack, unit: .milesPerHour).view
            
        }
    }
}
