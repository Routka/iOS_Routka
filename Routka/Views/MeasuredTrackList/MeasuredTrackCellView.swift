//
//  MeasuredTrackCellView.swift
//  Routka
//
//  Created by vladukha on 05.03.2026.
//
import SwiftUI

struct MeasuredTrackCellView: View {
    let measured: MeasuredTrack

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                type
                date
            }
            Spacer()
            duration
        }
    }
    
    private var type: some View {
        HStack(spacing: 4) {
            Image(systemName: measured.measurement.image)
                .foregroundStyle(Color.accentColor)
            Text(LocalizedStringKey(measured.measurement.name),
                 tableName: "MeasurementPresets")
                .font(.headline)
                .foregroundStyle(Color.primary)
        }
    }
    
    private var date: some View {
        HStack {
            let startDate = measured.startDate
            Text(startDate, style: .date)
            
            Text(startDate, style: .time)
        }
        .font(.caption)
        .foregroundStyle(Color.secondary)
    }
    
    @ViewBuilder
    private var duration: some View {
        if let stop = measured.track.stopDate {
            let duration = stop.timeIntervalSince(measured.track.startDate)
            HStack(spacing: 4) {
                Text(TimeIntervalFormatter.string(from: duration) ?? "")
                    .font(.subheadline)
                    .foregroundStyle(Color.primary)
                Image(systemName: "timer")
                    .foregroundStyle(Color.green.mix(with: .white, by: 0.2))
            }
            
        }
    }
}

#Preview {
    List {
        Button{} label: {
            MeasuredTrackCellView(measured: .init(id: "", measurement: .reachingDistance(30, name: "1/2 mile"), track: .filledTrack))
        }
    }
}
