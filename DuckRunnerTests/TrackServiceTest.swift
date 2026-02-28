//
//  TrackServiceTest.swift
//  DuckRunnerTests
//
//  Created by vladukha on 15.02.2026.
//

import Testing
internal import Foundation
import CoreLocation
@testable import DuckRunner
internal import Combine

@Suite("TrackService tests")
struct TrackServiceTests {
    
    @Test("append point throws .noCurrentTrack if no track started")
    func appendTrackPosition_noCurrentTrack_throws() async throws {
        let service = await TrackRecordingService()
        let pt = await TrackPoint(position: .init(latitude: 0, longitude: 0), speed: 0, date: .now)
        do {
            try await service.appendTrackPosition(pt)
            Issue.record("Should have thrown")
        } catch {
            #expect(error == .noCurrentTrack)
        }
    }

    @Test("append point throws .currentTrackIsFinished if track is stopped")
    func appendTrackPosition_stoppedTrack_throws() async throws {
        let service = await TrackRecordingService()
        await service.startTrack(at: Date())
        _ = try await service.stopTrack(at: Date())
        let pt = await TrackPoint(position: .init(latitude: 0, longitude: 0), speed: 0, date: .now)
        do {
            try await service.appendTrackPosition(pt)
            Issue.record("Should have thrown")
        } catch {
            #expect(error == .currentTrackIsFinished)
        }
    }

    @Test("append point works for active track")
    func appendTrackPosition_activeTrack_succeeds() async throws {
        let service = await TrackRecordingService()
        await service.startTrack(at: Date())
        let pt = await TrackPoint(position: .init(latitude: 10, longitude: 20), speed: 5, date: .now)
        try await service.appendTrackPosition(pt)
        await #expect(service.currentTrack?.points.count == 1)
        await #expect(service.currentTrack?.points.first?.position.latitude == 10)
    }

    @Test("stopTrack throws .noCurrentTrack if no track started")
    func stopTrack_noCurrentTrack_throws() async throws {
        let service = await TrackRecordingService()
        do {
            _ = try await service.stopTrack(at: Date())
            Issue.record("Should have thrown")
        } catch {
            #expect(error == .noCurrentTrack)
        }
    }

    @Test("stopTrack works for active track")
    func stopTrack_activeTrack_succeeds() async throws {
        let service = await TrackRecordingService()
        let start = Date()
        await service.startTrack(at: start)
        let stop = Date().addingTimeInterval(10)
        try await service.stopTrack(at: stop)
        await #expect(service.currentTrack?.startDate == start)
        await #expect(service.currentTrack?.stopDate == stop)
    }
}
