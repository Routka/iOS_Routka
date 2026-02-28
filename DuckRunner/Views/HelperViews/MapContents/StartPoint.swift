//
//  StartPoint.swift
//  DuckRunner
//
//  Created by vladukha on 26.02.2026.
//
import SwiftUI
import MapKit

extension MapContents {
    /// Start checkpoint
    @MapContentBuilder
    static public func startPoint(_ trackPoint: TrackPoint) -> some MapContent {
        
        Annotation(coordinate: trackPoint.position,
                   anchor: .bottom) {
            StartPointView(startPoint: trackPoint)
        } label: {
        }

    }
}

private struct StartPointView: View {
    let startPoint: TrackPoint

    
    var body: some View {
        VStack(spacing: 4) {
            Text("START")
                .stroke(color: .black, width: 1)
            .bold()
            let unFilledAmount = 0.75
            let degree = (180 - (360 - (360 * (unFilledAmount)))) / 2
            ZStack {
                Circle()
                   .trim(from: 0.0,
                         to: unFilledAmount)
                   .stroke(Color.gray,
                           style: .init(lineWidth: 4,
                                        lineCap: .round))
                   .rotationEffect(.degrees(180))
                   .rotationEffect(.degrees((-degree)))
            }
               .frame(width: 30)
        }
    }
}

#Preview {
    VStack {
        Map() {
//            MapContents.speedTrack(.filledTrack)
            MapContents.startPoint(Track.filledTrack.points.first!)
        }
    }
}
#Preview("Inside View") {
    StartPointView(startPoint: Track.filledTrack.points.first!)
}
