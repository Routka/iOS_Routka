//
//  TrackPoint.swift
//  DuckRunner
//
//  Created by vladukha on 19.02.2026.
//


import Testing
import CoreLocation
@testable import DuckRunner


@Suite("TrackReplayValidator initialization")
struct TrackReplayValidatorTests {

    // Approximate meters-per-degree for longitude at given latitude
    private func metersPerDegreeLongitude(at latitude: Double) -> Double {
        return 111_320.0 * cos(latitude * .pi / 180.0)
    }

    private func coordinate(eastOffsetMeters: Double, from base: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let mPerDegLon = metersPerDegreeLongitude(at: base.latitude)
        let deltaLon = eastOffsetMeters / mPerDegLon
        return CLLocationCoordinate2D(latitude: base.latitude, longitude: base.longitude + deltaLon)
    }
    
    private func offsetNorth(_ coord: CLLocationCoordinate2D, meters: Double) -> CLLocationCoordinate2D {
        // Approximate meters per degree latitude is ~111,320m
        let deltaLat = meters / 111_320.0
        return CLLocationCoordinate2D(latitude: coord.latitude + deltaLat, longitude: coord.longitude)
    }

    @Test("Correct Checkpoint Creation")
    func createsCheckpointsEvery500m() async throws {
        // Build a straight line of points every ~2m for 2km
        let base = CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
        let stepMeters: Double = 2
        let totalMeters: Double = 2000
        var points: [TrackPoint] = []
        var current: Double = 0
        while current <= totalMeters {
            let coord = coordinate(eastOffsetMeters: current, from: base)
            await points.append(TrackPoint(position: coord, speed: 0, date: .now))
            current += stepMeters
        }
        let track = await Track(points: points, startDate: .now)

        let validator = await TrackReplayValidator(replayingTrack: track, checkPointInterval: 500)
        let count = await validator.checkpoints.count

        #expect(count == 4, "Expected checkpoints at 500, 1000, 1500, 2000 meters")
    }
    
    
    @Test("Completion is 1.0 when following a path offset ~15m from original")
    func completionIsOneForParallelOffsetPath() async throws {
        // Build a straight line of points every ~250m for 2km
        let base = CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
        let stepMeters: Double = 2
        let totalMeters: Double = 2000
        var points: [TrackPoint] = []
        var current: Double = 0
        while current <= totalMeters {
            let coord = coordinate(eastOffsetMeters: current, from: base)
            await points.append(TrackPoint(position: coord, speed: 0, date: .now))
            current += stepMeters
        }
        let track = await Track(points: points, startDate: .now)

        // Initialize validator
        let validator = await TrackReplayValidator(replayingTrack: track, checkPointInterval: 50)
        await validator.startValidatingReplay()
        // Create a parallel path offset ~15m to the north for each point
        let offsetMeters: Double = 15
        // Feed the validator with offset points simulating a replay near the checkpoints
        for p in points {
            let offsetCoord = await offsetNorth(p.position, meters: offsetMeters)
            let offsetPoint = await TrackPoint(position: offsetCoord, speed: 0, date: .now)
            await validator.passedPoint(offsetPoint)
        }

        let completion = await validator.trackCompletionByCheckpoints()
        #expect(completion == 1.0, "Expected full completion when path is within ~15m of checkpoints")
    }
    
   
    
    @Test("Completion is 0.7 when following a path offset at 3 points out of 10")
    func completionIsOKForNotExactPath() async throws {
        // Build a straight line of points every ~2m for 5km
        let base = CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
        let stepMeters: Int = 500
        let totalMeters: Int = 5000
        var points: [TrackPoint] = []
        var pointsToOffset: Set<CLLocationCoordinate2D> = []
        // Current meters for point
        var current: Int = 0
        while current <= totalMeters {
            
            let coord = coordinate(eastOffsetMeters: Double(current), from: base)
            let point = await TrackPoint(position: coord, speed: 0, date: .now)
            points.append(point)
            
            // Remembering to offset points at 3 checkpoints
            if current == 500 ||
                current == 1500 ||
                current == 2000 {
                await pointsToOffset.insert(point.position)
                
            }
            
            current += stepMeters
        }
        let track = await Track(points: points, startDate: .now)

        // Initialize validator
        let validator = await TrackReplayValidator(replayingTrack: track, checkPointInterval: 500)
        await validator.startValidatingReplay()

        // Feed the validator with offset points simulating a replay near the checkpoints
        for p in points {
            let shouldOffsetGreatly = await pointsToOffset.contains(p.position)
            let offsetCoord: CLLocationCoordinate2D
            if shouldOffsetGreatly {
                // 55 is bigger than 50 - TrackCheckpoint threshold
                offsetCoord = await offsetNorth(p.position, meters: 55)
            } else {
                offsetCoord = await p.position
            }
            let offsetPoint = await TrackPoint(position: offsetCoord, speed: 0, date: .now)
            await validator.passedPoint(offsetPoint)
        }

        let completion = await validator.trackCompletionByCheckpoints()
        #expect(completion == 0.7, "Expected 70% completion when some points miss the checkpoint")
    }
}
