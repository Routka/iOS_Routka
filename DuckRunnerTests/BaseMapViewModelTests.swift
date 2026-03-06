import Testing
internal import Foundation
internal import Combine
import CoreLocation
@testable import DuckRunner

final class MockTrackService: TrackRecordingServiceProtocol {
    var stopPolicy: DuckRunner.RecordingAutoStopPolicy = .manual
    
    var stopPolicyProgress: Double = 1
    var isRecording: Bool = false
    
    func clearTrack() {
    }
    
    private(set) var currentTrack: DuckRunner.Track? = nil
    
    
    func startTrack(_ stopPolicy: DuckRunner.RecordingAutoStopPolicy) {
        isRecording = true
        let new = Track(points: [])
        currentTrack = new
    }
    
    func stopTrack() throws(DuckRunner.TrackServiceError) -> DuckRunner.Track {
        guard let current = currentTrack else {
            throw TrackServiceError.noCurrentTrack
        }
        guard isRecording else {
            throw TrackServiceError.currentTrackIsFinished
        }
        isRecording = false
        var updatedTrack = current
        currentTrack = updatedTrack
        return updatedTrack
    }
    
    func appendTrackPosition(_ point: DuckRunner.TrackPoint) throws(DuckRunner.TrackServiceError) -> DuckRunner.SuggestedRecordingAction {
        guard isRecording, var track = currentTrack else { return .allow }
        track.points.append(point)
        currentTrack = track
        return .allow
    }
}



// MARK: - Helpers

private func makeLocation(lat: Double = 37.3317, lon: Double = -122.0301, speed: CLLocationSpeed = 0) -> CLLocation {
    return CLLocation(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                      altitude: 0,
                      horizontalAccuracy: 1,
                      verticalAccuracy: 1,
                      course: 0,
                      speed: speed,
                      timestamp: Date())
}

@Suite("BaseMapViewModel Tests")
struct BaseMapViewModelTests {
    // MARK: - Recording track
    @Test("Updating location should add a new point to the track")
    func testProvidingLocationUpdatesTrackInfo() async throws {
        let trackService = MockTrackService()
        let vm = await BaseMapViewModel(dependencies: .mock(), trackRecordingService: trackService)

        // Start a track to allow appending
        await vm.startTrack()
        // Send one location
        
        await vm.receivedLocationUpdate(makeLocation(speed: 3.0))
        await #expect(vm.trackControlMode == .available)
        
        await #expect(trackService.currentTrack?.points.count == 1)
    }

    @Test("Updating location should update tracking speed")
    func testProvidingLocationUpdatesCurrentSpeed() async throws {
        let vm = await BaseMapViewModel(dependencies: .mock())

        await vm.startTrack()
        await vm.receivedLocationUpdate(makeLocation(speed: 5.5))
        let unwrapped = try #require(vm.currentSpeed)
        #expect(unwrapped == 5.5)
    }

    @Test("Starting action should start a new track")
    func testUpdatingTrackServiceCurrentTrackPropagates() async throws {
        let trackService = MockTrackService()
        let vm = await BaseMapViewModel(dependencies: .mock(), trackRecordingService: trackService)

        let start = Date()
        await trackService.startTrack(.manual)
        let trackOpt = await vm.trackRecordingService.currentTrack
        let track = try #require(trackOpt)
        #expect(trackService.isRecording)
        #expect(track.points.isEmpty)
    }

    @Test("Starting Track should clear prev track")
    func testStartTrackStartsTrackBothClearAndAfterAnother() async throws {
        let trackService = MockTrackService()
        let vm = await BaseMapViewModel(dependencies: .mock(), trackRecordingService: trackService)

        await vm.startTrack()
        let firstOpt = await vm.trackRecordingService.currentTrack
        let first = try #require(firstOpt)

        // Append a point, then start again to replace
        await vm.receivedLocationUpdate(makeLocation(speed: 1.0))
        await #expect(trackService.currentTrack?.points.count == 1)

        // Start again
        await vm.startTrack()
        let secondOpt = await vm.trackRecordingService.currentTrack
        let second = try #require(secondOpt)

        #expect(second.id != first.id)
        #expect(second.points.isEmpty)
    }
    
    @Test("Start action should work")
    func testStart() async throws {
        let trackService = MockTrackService()
        let vm = await BaseMapViewModel(dependencies: .mock(), trackRecordingService: trackService)

        // Start then stop
        await vm.startTrack()
        let startedTrack = await vm.trackRecordingService.currentTrack
        #expect(startedTrack?.stopDate == nil)
        #expect(startedTrack?.startDate != nil)
    }

    @Test("Stop action on non-existing track is a no-op")
    func testStopNonStartedError() async throws {
        let vm = await BaseMapViewModel(dependencies: .mock(), trackRecordingService: MockTrackService())

        // Stopping without starting should throw
        do {
            try await vm.stopTrack()
            Issue.record("Should have thrown")
        } catch TrackServiceError.noCurrentTrack {
            #expect(true)
        } catch {
            Issue.record("Wrong error")
        }
    }
    
    @Test("After error stop action, start should works")
    func testStartWorksAfterBadStart() async throws {
        let trackService = MockTrackService()
        let vm = await BaseMapViewModel(dependencies: .mock(), trackRecordingService: trackService)

        // Stopping without starting should throw
        do {
            try await vm.stopTrack()
            Issue.record("Should have thrown")
        } catch TrackServiceError.noCurrentTrack {
            #expect(true)
        } catch {
            Issue.record("Wrong error")
        }

        // Start then stop
        await vm.startTrack(.manual)
        #expect(trackService.isRecording)
        try await vm.stopTrack()
        
        #expect(!trackService.isRecording)
    }
    
    @Test("Stop Action should throw if called twice")
    func testSecondStopThrowsError() async throws {
        let trackService = MockTrackService()
        let vm = await BaseMapViewModel(dependencies: .mock(), trackRecordingService: trackService)

        // Start then stop
        await vm.startTrack(.manual)
        #expect(trackService.isRecording)
        try await vm.stopTrack()
        
        #expect(!trackService.isRecording)
        
        // Already stopped track should throw
        do {
            try await vm.stopTrack()
            Issue.record("Should have thrown")
        } catch TrackServiceError.currentTrackIsFinished {
            #expect(true)
        } catch {
            Issue.record("Wrong error")
        }

    }
    
    // MARK: - Selecting Replay track
    
    @Test("Selecting track these parameters should be correct")
    func testSelectingTrack() async throws {
        let vm = await BaseMapViewModel(dependencies: .mock())
        
        let track = await Track.filledTrack
        await vm.receiveReplayTrackAction(.select(track))
        
        guard let replayValidator = await vm.replayValidator else {
            Issue.record("ReplayValidator should not be nil")
            return
        }
        let receivedTrack = await replayValidator.track
        
        #expect(track.id == receivedTrack.id)
        await #expect(vm.trackRecordingService.currentTrack == nil)
        #expect(vm.replayValidator != nil)
        #expect(vm.trackControlMode == .unavailable)
        await #expect(replayValidator.startReplayCheckpoint!.point.position == track.points.first?.position)
        await #expect(replayValidator.stopReplayCheckpoint!.point.position == track.points.last?.position)
    }
    
    @Test("DeSelecting track these parameters should be correct")
    func testDeSelectingTrack() async throws {
        let vm = await BaseMapViewModel(dependencies: .mock())
        
        let track = await Track.filledTrack
        await vm.receiveReplayTrackAction(TrackReplayAction.select(track))
        
        guard let replayValidator = await vm.replayValidator else {
            Issue.record("ReplayValidator should not be nil")
            return
        }
        
        #expect(track.id == replayValidator.track.id)
        await #expect(vm.trackRecordingService.currentTrack == nil)
        #expect(vm.replayValidator != nil)
        #expect(vm.trackControlMode == .unavailable)
        
        await #expect(replayValidator.startReplayCheckpoint!.point.position == track.points.first?.position)
        await #expect(replayValidator.stopReplayCheckpoint!.point.position == track.points.last?.position)
        
        // force start
        await vm.startTrack()
        
        await vm.receivedLocationUpdate(.init(latitude: 30, longitude: 30))
        
        await vm.receiveReplayTrackAction(TrackReplayAction.deselect)
        
        #expect(vm.replayValidator == nil)
        #expect(vm.trackControlMode == .available)
    }
    
    // MARK: - Selecting Classical track
    
    @Test("Classical selection wrong location should be not available to start")
    func testClassicalTrackAwayNotStartable() async throws {
        let vm = await BaseMapViewModel(dependencies: .mock())
        
        var track = await Track.filledTrack
        await track.changeType(to: .classical)
        #expect(track.type == .classical)
        
        await vm.receiveReplayTrackAction(TrackReplayAction.select(track))
        guard let replayValidator = await vm.replayValidator else {
            Issue.record("ReplayValidator should not be nil")
            return
        }
        #expect(track.id == replayValidator.track.id)
        
        #expect(vm.trackControlMode == .unavailable)
        
        let startCoordinate = try #require(track.points.first?.position)
        let farLocation = startCoordinate.offsetToNorth(by: 150)
        
        await vm.receivedLocationUpdate(.init(latitude: farLocation.latitude, longitude: farLocation.longitude))
        
        await #expect(vm.trackControlMode != .available)
    }
    
    @Test("Classical selection correct location should be available to start")
    func testClassicalTrackCloseStartable() async throws {
        let vm = await BaseMapViewModel(dependencies: .mock())
        
        var track = await Track.filledTrack
        await track.changeType(to: .classical)
        #expect(track.type == .classical)
        
        await vm.receiveReplayTrackAction(TrackReplayAction.select(track))
        guard let replayValidator = await vm.replayValidator else {
            Issue.record("ReplayValidator should not be nil")
            return
        }
        #expect(track.id == replayValidator.track.id)
        
        #expect(vm.trackControlMode == .unavailable)
        
        let startCoordinate = try #require(track.points.first?.position)
        for meters in 0..<Int(SettingsService.shared.checkpointDistanceActivateThreshold) {
            let farLocation = startCoordinate.offsetToNorth(by: Double(meters))
            
            await vm.receivedLocationUpdate(.init(latitude: farLocation.latitude, longitude: farLocation.longitude))
            await #expect(vm.trackControlMode == .available)
        }
        
        let farLocation = startCoordinate.offsetToNorth(by: SettingsService.shared.checkpointDistanceActivateThreshold + 10)
        
        await vm.receivedLocationUpdate(.init(latitude: farLocation.latitude, longitude: farLocation.longitude))
        await #expect(vm.trackControlMode != .available)
    }
    
    @Test("Classical selection corrent location high speed should be not available to start")
    func testClassicalTrackCloseNotStartable() async throws {
        let vm = await BaseMapViewModel(dependencies: .mock())
        
        var track = await Track.filledTrack
        await track.changeType(to: .classical)
        #expect(track.type == .classical)
        
        await vm.receiveReplayTrackAction(TrackReplayAction.select(track))
        guard let replayValidator = await vm.replayValidator else {
            Issue.record("ReplayValidator should not be nil")
            return
        }
        #expect(track.id == replayValidator.track.id)
        
        #expect(vm.trackControlMode == .unavailable)
        
        let startCoordinate = try #require(track.points.first?.position)
        
        let location = CLLocation(coordinate: startCoordinate,
                                  altitude: 0,
                                  horizontalAccuracy: 1,
                                  verticalAccuracy: 1,
                                  course: 0,
                                  speed: 20,
                                  timestamp: .now)

        await vm.receivedLocationUpdate(location)
        await #expect(vm.trackControlMode != .available)
    }
    
    
    // MARK: - Selecting speedtrap replay
    
    /*
     selected speedtrap track to replay
     
     send location
     if we are inside start point track recording should start
     */
    @Test("Speedtrap selection correct location should start")
    func testSpeedtrapTrackCloseStarting() async throws {
        let trackService = MockTrackService()
        let vm = await BaseMapViewModel(dependencies: .mock(), trackRecordingService: trackService)
        
        var track = await Track.filledTrack
        await track.changeType(to: .speedtrap)
        #expect(track.type == .speedtrap)
        
        await vm.receiveReplayTrackAction(TrackReplayAction.select(track))
        guard let replayValidator = await vm.replayValidator else {
            Issue.record("ReplayValidator should not be nil")
            return
        }
        #expect(track.id == replayValidator.track.id)
        
        let startCoordinate = try #require(track.points.first?.position)
        
        
        let location = CLLocation(coordinate: startCoordinate,
                                  altitude: 0,
                                  horizontalAccuracy: 1,
                                  verticalAccuracy: 1,
                                  course: 0,
                                  speed: 20,
                                  timestamp: .now)
        
        await vm.receivedLocationUpdate(location)
        #expect(trackService.isRecording)
    }
    
    /*
     send location
     if we are outside start point nothing should happen
         */
    
    @Test("Speedtrap selection wrong location should not start")
    func testSpeedtrapTrackWrongLocationNotStarting() async throws {
        let trackService = MockTrackService()
        let vm = await BaseMapViewModel(dependencies: .mock(), trackRecordingService: trackService)
        
        var track = await Track.filledTrack
        await track.changeType(to: .speedtrap)
        #expect(track.type == .speedtrap)
        
        await vm.receiveReplayTrackAction(TrackReplayAction.select(track))
        guard let replayValidator = await vm.replayValidator else {
            Issue.record("ReplayValidator should not be nil")
            return
        }
        #expect(track.id == replayValidator.track.id)
        
        let startCoordinate = try #require(track.points.first?.position)
        
        
        let location = CLLocation(coordinate: startCoordinate.offsetToNorth(by: 500),
                                  altitude: 0,
                                  horizontalAccuracy: 1,
                                  verticalAccuracy: 1,
                                  course: 0,
                                  speed: 20,
                                  timestamp: .now)

        await vm.receivedLocationUpdate(location)
        #expect(trackService.isRecording == false)
    }
    
    /*
     start Track recording
     send location
     if we are inside stop point track recording should stop
         */
    
    @Test("Speedtrap selection correct location should stop")
    func testSpeedtrapTrackCorrectLocationStoping() async throws {
        let trackService = MockTrackService()
        let vm = await BaseMapViewModel(dependencies: .mock(), trackRecordingService: trackService)
        
        var track = await Track.filledTrack
        await track.changeType(to: .speedtrap)
        #expect(track.type == .speedtrap)
        
        await vm.receiveReplayTrackAction(TrackReplayAction.select(track))
        guard let replayValidator = await vm.replayValidator else {
            Issue.record("ReplayValidator should not be nil")
            return
        }
        #expect(track.id == replayValidator.track.id)
        
        let startCoordinate = try #require(track.points.first?.position)
        
        #expect(!trackService.isRecording)
        let location = CLLocation(coordinate: startCoordinate,
                                  altitude: 0,
                                  horizontalAccuracy: 1,
                                  verticalAccuracy: 1,
                                  course: 0,
                                  speed: 20,
                                  timestamp: .now)
        
        await vm.receivedLocationUpdate(location)
        #expect(trackService.isRecording)
        
        let stopCoordinate = try #require(track.points.last?.position)
        
        let stopLocation = CLLocation(coordinate: stopCoordinate,
                                  altitude: 0,
                                  horizontalAccuracy: 1,
                                  verticalAccuracy: 1,
                                  course: 0,
                                  speed: 20,
                                  timestamp: .now)
        
        await vm.receivedLocationUpdate(stopLocation)
        #expect(!trackService.isRecording)
    }
    
    @Test("Replaying track with checkpoints when track not started should not pass checkpoints") 
    func testNonStartedTrackIgnoresCheckpoints() async throws {
        let trackService = MockTrackService()
        let vm = await BaseMapViewModel(dependencies: .mock(), trackRecordingService: trackService)
        
        var track = await Track.filledTrack
        await track.changeType(to: .speedtrap)
        #expect(track.type == .speedtrap)
        
        await vm.receiveReplayTrackAction(TrackReplayAction.select(track))
        guard let replayValidator = await vm.replayValidator else {
            Issue.record("ReplayValidator should not be nil")
            return
        }
        #expect(track.id == replayValidator.track.id)
        
        #expect(!trackService.isRecording)
        
        #expect(!replayValidator.checkpoints.isEmpty)
        
        let randomCheckpoint = try #require(replayValidator.checkpoints.first)
        let checkpointLocation = await CLLocation(coordinate: randomCheckpoint.value.point.position,
                                      altitude: 0,
                                      horizontalAccuracy: 1,
                                      verticalAccuracy: 1,
                                      course: 0,
                                      speed: 20,
                                      timestamp: .now)
        
        await vm.receivedLocationUpdate(checkpointLocation)
        
        #expect(!trackService.isRecording)
        
        #expect(!replayValidator.checkpoints.contains(where: {$0.value.checkPointPassed}))
    }
     
}

