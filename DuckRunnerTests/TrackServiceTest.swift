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
        await service.startTrack(.manual)
        _ = try await service.stopTrack()
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
        await service.startTrack(.manual)
        let pt = await TrackPoint(position: .init(latitude: 10, longitude: 20), speed: 5, date: .now)
        try await service.appendTrackPosition(pt)
        await #expect(service.currentTrack?.points.count == 1)
        await #expect(service.currentTrack?.points.first?.position.latitude == 10)
    }

    @Test("stopTrack throws .noCurrentTrack if no track started")
    func stopTrack_noCurrentTrack_throws() async throws {
        let service = await TrackRecordingService()
        do {
            _ = try await service.stopTrack()
            Issue.record("Should have thrown")
        } catch {
            #expect(error == .noCurrentTrack)
        }
    }

    @Test("stopTrack works for active track")
    func stopTrack_activeTrack_succeeds() async throws {
        let service = await TrackRecordingService()
        let start = Date()
        let stop = Date().addingTimeInterval(10)
        await service.startTrack(.manual)
        try await service.appendTrackPosition(.init(position: .init(latitude: 30, longitude: 30), speed: 12, date: start))
        try await service.appendTrackPosition(.init(position: .init(latitude: 30, longitude: 30), speed: 12, date: stop))
        try await service.stopTrack()
        await #expect(service.currentTrack?.startDate == start)
        await #expect(service.currentTrack?.stopDate == stop)
    }
}
