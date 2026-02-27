//
//  CheckPoint.swift
//  DuckRunner
//
//  Created by vladukha on 26.02.2026.
//


import MapKit
import SwiftUI

extension MapContents {
    /// Passable Checkpoint
    @MapContentBuilder
    static public func checkPoint(_ trackPoint: TrackCheckPoint) -> some MapContent {
        
        Annotation(coordinate: trackPoint.point.position,
                   anchor: .center) {
            CheckPointView(trackPoint: trackPoint)
        } label: {
        }

    }
}

private struct CheckPointView: View {
    let trackPoint: TrackCheckPoint
    var body: some View {
        VStack(spacing: 1) {
            if trackPoint.checkPointPassed {
                Image(systemName: "flag.pattern.checkered.2.crossed")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.green)
                    .stroke(color: .black, width: 0.2)
            } else {
                Image(systemName: "flag.2.crossed")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.gray)
                    .stroke(color: .black, width: 0.2)
            }
        }
        .frame(width: 30)
        .animation(.bouncy(duration: 0.5), value: trackPoint.checkPointPassed)
    }
}

#Preview {
    @Previewable @State var lastCheckpoint = TrackCheckPoint(point: Track.filledTrack.points.last!, distanceThreshold: 50)
    VStack {
        Button("Pass") {
            lastCheckpoint.setCheckpointPassing(to: true)
        }
        Map() {
            var checkpoint = TrackCheckPoint(point: Track.filledTrack.points.first!, distanceThreshold: 50)
            let _ = checkpoint.setCheckpointPassing(to: true)
            MapContents.checkPoint(checkpoint)
            MapContents.checkPoint(lastCheckpoint)
        }
    }
}

#Preview("Inside View") {
    @Previewable @State var lastCheckpoint = TrackCheckPoint(point: Track.filledTrack.points.last!, distanceThreshold: 50)
    HStack {
        CheckPointView(trackPoint: lastCheckpoint)
        var checkpoint = TrackCheckPoint(point: Track.filledTrack.points.first!, distanceThreshold: 50)
        let _ = checkpoint.setCheckpointPassing(to: true)
        CheckPointView(trackPoint: checkpoint)
    }
}
