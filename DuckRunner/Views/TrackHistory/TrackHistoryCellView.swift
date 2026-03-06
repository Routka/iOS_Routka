//
//  TrackHistoryCellView.swift
//  DuckRunner
//
//  Created by vladukha on 16.02.2026.
//

import SwiftUI

/// View Cell of a Track in history list
struct TrackHistoryCellView: View {
    let track: Track
    let unit: UnitSpeed
    let mapSnapshotGenerator: any MapSnapshotGeneratorProtocol
    let mapSnippetCache: any TrackMapSnippetCacheProtocol
    
    /// Initializes the history view with the given view model.
    init(track: Track, unit: UnitSpeed,
         dependencies: DependencyManager) {
        self.track = track
        self.unit = unit
        self.mapSnippetCache = dependencies.mapSnippetCache
        self.mapSnapshotGenerator = dependencies.mapSnapshotGenerator
    }
    
    var body: some View {
        VStack() {
            HStack {
                date
                Spacer()
                Image(systemName: "chevron.right")
            }
            time
                .frame(maxWidth: .infinity, alignment: .leading)
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
    
    private var time: some View {
        Text(track.startDate.toString(format: "EEE HH:mm"))
            .font(.caption)
            .fontWeight(.semibold)
            .opacity(0.7)
    }
    
    private var date: some View {
        let date = track.startDate.toString(style: .medium)
        return Text(date)
            .font(.title2)
            .bold()
    }
    
    private var mapSnippet: some View {
        MapSnippetView(mapSnippetCache: mapSnippetCache,
                       mapSnapshotGenerator: mapSnapshotGenerator,
                       track: track)
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 0)
            
    }
}


#Preview {
    ZStack {
//        Color.cyan.opacity(0.3)
        VStack {
            TrackHistoryCellView(track: .filledTrack,
                                 unit: .kilometersPerHour,
                                 dependencies: .mock())
            TrackHistoryCellView(track: .filledTrack,
                                 unit: .milesPerHour,
                                 dependencies: .mock())
        }
    }
}
