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
    let passColor = Color.green
    let unpassColor = Color.gray
    
    private var baseCircle: some View {
        let unFilledAmount = 0.15
        let degree = (360 * unFilledAmount) / 2
        return Circle()
            .trim(from: 0.0,
                  to: trackPoint.checkPointPassed ? 0.5 : unFilledAmount)
            .stroke(trackPoint.checkPointPassed ? passColor : unpassColor)
            .rotationEffect(.degrees(-(degree)))
        
    }
    var body: some View {
        ZStack {
            baseCircle
            baseCircle
                .rotationEffect(.degrees(180))
            Circle()
                .stroke(trackPoint.checkPointPassed ? unpassColor : passColor,
                        lineWidth: 1)
                .padding(.horizontal, 5)
                .opacity(0.6)

        }
        .frame(width: 20)
        .animation(.easeInOut, value: trackPoint.checkPointPassed)
    }
}

#Preview {
    @Previewable @State var lastCheckpoint = TrackCheckPoint(point: Track.filledTrack.points.last!, distanceThreshold: 50)
    VStack {
        HStack {
            Button("Pass") {
                lastCheckpoint.setCheckpointPassing(to: true)
            }
            Button("UNPass") {
                lastCheckpoint.setCheckpointPassing(to: false)
            }
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
    VStack {
        HStack {
            Button("Pass") {
                lastCheckpoint.setCheckpointPassing(to: true)
            }
            Button("UNPass") {
                lastCheckpoint.setCheckpointPassing(to: false)
            }
        }
        HStack {
            CheckPointView(trackPoint: lastCheckpoint)
            var checkpoint = TrackCheckPoint(point: Track.filledTrack.points.first!, distanceThreshold: 50)
            let _ = checkpoint.setCheckpointPassing(to: true)
            CheckPointView(trackPoint: checkpoint)
        }
    }
}
