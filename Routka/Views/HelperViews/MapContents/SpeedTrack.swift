//
//  SpeedTrack.swift
//  Routka
//
//  Created by vladukha on 26.02.2026.
//
import SwiftUI
import MapKit

extension MapContents {
    /// Track polyline that colors the track by speed points
    @MapContentBuilder
    static public func speedTrack(_ track: Track) -> some MapContent {
        Self.speedTrack(track.points)
    }
    
    /// Track polyline that colors the track by speed points
    @MapContentBuilder
    static public func speedTrack(_ trackPoints: [TrackPoint] ) -> some MapContent {
        let segments = mergedSpeedSegments(for: trackPoints)

        if segments.isEmpty == false {
            ForEach(segments) { segment in
                MapPolyline(
                    coordinates: segment.coordinates,
                    contourStyle: .straight
                )
                .stroke(Color.init(uiColor: segment.bucket.color()),
                        style: .init(lineWidth: 6,
                                     lineCap: .round,
                                     lineJoin: .round))
            }
        }
    }

    private static func mergedSpeedSegments(for trackPoints: [TrackPoint]) -> [SpeedTrackSegment] {
        guard trackPoints.count > 1 else { return [] }

        var segments: [SpeedTrackSegment] = []
        var currentBucket = SpeedBucket(for: trackPoints[1].speed)
        var currentCoordinates: [CLLocationCoordinate2D] = [
            trackPoints[0].position,
            trackPoints[1].position
        ]

        for index in 1..<(trackPoints.count - 1) {
            let nextPoint = trackPoints[index + 1]
            let nextBucket = SpeedBucket(for: nextPoint.speed)

            if nextBucket == currentBucket {
                currentCoordinates.append(nextPoint.position)
                continue
            }

            segments.append(
                SpeedTrackSegment(
                    bucket: currentBucket,
                    coordinates: currentCoordinates
                )
            )
            currentBucket = nextBucket
            currentCoordinates = [
                trackPoints[index].position,
                nextPoint.position
            ]
        }

        segments.append(
            SpeedTrackSegment(
                bucket: currentBucket,
                coordinates: currentCoordinates
            )
        )

        return segments
    }
}

private struct SpeedTrackSegment: Identifiable {
    let id = UUID()
    let bucket: SpeedBucket
    let coordinates: [CLLocationCoordinate2D]
}

#Preview {
    Map() {
        MapContents.speedTrack(.filledTrack)
    }
}
