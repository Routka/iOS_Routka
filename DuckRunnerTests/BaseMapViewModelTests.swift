import Testing
internal import Foundation
internal import Combine
import CoreLocation
@testable import DuckRunner

final class MockTrackService: LiveTrackServiceProtocol {
    var currentTrack: CurrentValueSubject<DuckRunner.Track?, Never> = .init(nil)
    
    private(set) var isActive = false

    func startTrack(at date: Date) {
        isActive = true
        let new = Track(points: [], startDate: date)
        currentTrack.send(new)
    }

    func stopTrack(at date: Date) throws(TrackServiceError) -> Track {
        if currentTrack.value == nil {
            throw TrackServiceError.noCurrentTrack
        } else if isActive == false {
            throw TrackServiceError.currentTrackIsFinished
        } else {
            isActive = false
            var updatedTrack = currentTrack.value
            updatedTrack?.stopDate = date
            currentTrack.send(updatedTrack)
            return updatedTrack!
        }
    }

    func appendTrackPosition(_ point: DuckRunner.TrackPoint) throws(DuckRunner.TrackServiceError) {
        guard isActive, var track = currentTrack.value else { return }
        track.points.append(point)
        currentTrack.send(track)
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
        let vm = await BaseMapViewModel(dependencies: .mock(trackService: trackService))

        // Start a track to allow appending
        await vm.startTrack()
        // Send one location
        
        await vm.receivedLocationUpdate(makeLocation(speed: 3.0))
        await #expect(vm.isTrackControlAvailable == true)
        
        await #expect(trackService.currentTrack.value?.points.count == 1)
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
        let dependencies = await DependencyManager.mock(trackService: trackService)
        let vm = await BaseMapViewModel(dependencies: dependencies)

        let start = Date()
        await trackService.startTrack(at: start)

        let trackOpt = await vm.currentTrack
        let track = try #require(trackOpt)
        #expect(track.startDate == start)
        #expect(track.points.isEmpty)
    }

    @Test("Starting Track should clear prev track")
    func testStartTrackStartsTrackBothClearAndAfterAnother() async throws {
        let trackService = MockTrackService()
        let vm = await BaseMapViewModel(dependencies: .mock(trackService: trackService))

        await vm.startTrack()
        let firstOpt = await vm.currentTrack
        let first = try #require(firstOpt)

        // Append a point, then start again to replace
        await vm.receivedLocationUpdate(makeLocation(speed: 1.0))
        await #expect(trackService.currentTrack.value?.points.count == 1)

        // Start again
        await vm.startTrack()
        let secondOpt = await vm.currentTrack
        let second = try #require(secondOpt)

        #expect(second.startDate >= first.startDate)
        #expect(second.points.isEmpty)
    }
    
    @Test("Start action should work")
    func testStart() async throws {
        let trackService = MockTrackService()
        let dependencies = await DependencyManager.mock(trackService: trackService)
        let vm = await BaseMapViewModel(dependencies: dependencies)

        // Start then stop
        await vm.startTrack()
        let startedTrack = await vm.currentTrack
        await #expect(startedTrack?.stopDate == nil)
        await #expect(startedTrack?.startDate != nil)
    }

    @Test("Stop action on non-existing track is a no-op")
    func testStopNonStartedError() async throws {
        let vm = await BaseMapViewModel(dependencies: .mock(trackService: MockTrackService()))

        // Stopping without starting should throw
        do {
            try await vm.stopTrack()
            Issue.record("Should have thorwn")
        } catch TrackServiceError.noCurrentTrack {
            #expect(true)
        } catch {
            Issue.record("Wrong error")
        }
    }
    
    @Test("After error stop action, start should works")
    func testStartWorksAfterBadStart() async throws {
        let trackService = MockTrackService()
        let vm = await BaseMapViewModel(dependencies: .mock(trackService: trackService))

        // Stopping without starting should throw
        do {
            try await vm.stopTrack()
            Issue.record("Should have thorwn")
        } catch TrackServiceError.noCurrentTrack {
            #expect(true)
        } catch {
            Issue.record("Wrong error")
        }

        // Start then stop
        await vm.startTrack()
        #expect(trackService.isActive)
        try await vm.stopTrack()
        
        #expect(!trackService.isActive)
    }
    
    @Test("Stop Action should throw if called twice")
    func testSecondStopThrowsError() async throws {
        let trackService = MockTrackService()
        let vm = await BaseMapViewModel(dependencies: .mock(trackService: trackService))

        // Start then stop
        await vm.startTrack()
        #expect(trackService.isActive)
        try await vm.stopTrack()
        
        #expect(!trackService.isActive)
        
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
        
        let receivedTrack = await vm.replayTrack
        
        #expect(track.id == receivedTrack?.id)
        #expect(vm.currentTrack == nil)
        #expect(vm.replayValidator != nil)
        #expect(vm.isTrackControlAvailable == false)
        await #expect(vm.startReplayCheckpoint?.point.position == track.points.first?.position)
        await #expect(vm.stopReplayCheckpoint?.point.position == track.points.last?.position)
        
    }
    
    @Test("DeSelecting track these parameters should be correct")
    func testDeSelectingTrack() async throws {
        let vm = await BaseMapViewModel(dependencies: .mock())
        
        let track = await Track.filledTrack
        await vm.receiveReplayTrackAction(.select(track))
        let receivedTrack = await vm.replayTrack
        
        #expect(track.id == receivedTrack?.id)
        #expect(vm.currentTrack == nil)
        #expect(vm.replayValidator != nil)
        #expect(vm.isTrackControlAvailable == false)
        
        await #expect(vm.startReplayCheckpoint?.point.position == track.points.first?.position)
        await #expect(vm.stopReplayCheckpoint?.point.position == track.points.last?.position)
        
        // force start
        await vm.startTrack()
        
        await vm.receivedLocationUpdate(.init(latitude: 30, longitude: 30))
        
        await vm.receiveReplayTrackAction(.deselect)
        let receivedNoTrack = await vm.replayTrack
        #expect(receivedNoTrack == nil)
        #expect(vm.replayTrack == nil)
        #expect(vm.replayValidator == nil)
        #expect(vm.isTrackControlAvailable == true)
        #expect(vm.stopReplayCheckpoint == nil)
        #expect(vm.startReplayCheckpoint == nil)
    }
    
    // MARK: - Selecting Classical track
    
    @Test("Classical selection wrong location should be not available to start")
    func testClassicalTrackAwayNotStartable() async throws {
        let vm = await BaseMapViewModel(dependencies: .mock())
        
        var track = await Track.filledTrack
        await track.changeType(to: .classical)
        await #expect(track.type == .classical)
        
        await vm.receiveReplayTrackAction(.select(track))
        let receivedTrack = await vm.replayTrack
        #expect(track.id == receivedTrack?.id)
        
        await #expect(vm.isTrackControlAvailable == false)
        
        let startCoordinate = try #require(track.points.first?.position)
        let farLocation = startCoordinate.offsetToNorth(by: 150)
        
        await vm.receivedLocationUpdate(.init(latitude: farLocation.latitude, longitude: farLocation.longitude))
        
        let isTrackAvailable = await vm.isTrackControlAvailable
        #expect(isTrackAvailable == false)
    }
    
    @Test("Classical selection correct location should be available to start")
    func testClassicalTrackCloseStartable() async throws {
        let vm = await BaseMapViewModel(dependencies: .mock())
        
        var track = await Track.filledTrack
        await track.changeType(to: .classical)
        await #expect(track.type == .classical)
        
        await vm.receiveReplayTrackAction(.select(track))
        let receivedTrack = await vm.replayTrack
        #expect(track.id == receivedTrack?.id)
        
        await #expect(vm.isTrackControlAvailable == false)
        
        let startCoordinate = try #require(track.points.first?.position)
        for meters in 0..<Int(SettingsService.shared.checkpointDistanceActivateThreshold) {
            let farLocation = startCoordinate.offsetToNorth(by: Double(meters))
            
            await vm.receivedLocationUpdate(.init(latitude: farLocation.latitude, longitude: farLocation.longitude))
            await #expect(vm.isTrackControlAvailable == true)
        }
        
        let farLocation = startCoordinate.offsetToNorth(by: SettingsService.shared.checkpointDistanceActivateThreshold + 10)
        
        await vm.receivedLocationUpdate(.init(latitude: farLocation.latitude, longitude: farLocation.longitude))
        await #expect(vm.isTrackControlAvailable == false)
    }
    
    @Test("Classical selection corrent location high speed should be not available to start")
    func testClassicalTrackCloseNotStartable() async throws {
        let vm = await BaseMapViewModel(dependencies: .mock())
        
        var track = await Track.filledTrack
        await track.changeType(to: .classical)
        await #expect(track.type == .classical)
        
        await vm.receiveReplayTrackAction(.select(track))
        let receivedTrack = await vm.replayTrack
        #expect(track.id == receivedTrack?.id)
        
        await #expect(vm.isTrackControlAvailable == false)
        
        let startCoordinate = try #require(track.points.first?.position)
        
        
        let location = CLLocation(coordinate: startCoordinate,
                                  altitude: 0,
                                  horizontalAccuracy: 1,
                                  verticalAccuracy: 1,
                                  course: 0,
                                  speed: 20,
                                  timestamp: .now)

        await vm.receivedLocationUpdate(location)
        await #expect(vm.isTrackControlAvailable == false)
    }
    
    
    // MARK: - Selecting speedtrap replay
    final class TrackStartDetectMock: LiveTrackServiceProtocol {
        var startedTrack: Bool = false
        var currentTrack: CurrentValueSubject<DuckRunner.Track?, Never> = .init(nil)
        
        func appendTrackPosition(_ point: DuckRunner.TrackPoint) throws(DuckRunner.TrackServiceError) {
        }
        
        func startTrack(at date: Date) {
            self.startedTrack = true
        }
        
        func stopTrack(at date: Date) throws(DuckRunner.TrackServiceError) -> DuckRunner.Track {
            return .filledTrack
        }
    }
    
    /*
     selected speedtrap track to replay
     
     send location
     if we are inside start point track recording should start
     */
    @Test("Speedtrap selection correct location should start")
    func testSpeedtrapTrackCloseStarting() async throws {
        
        
        let trackService = TrackStartDetectMock()
        let vm = await BaseMapViewModel(dependencies: .mock(trackService: trackService))
        
        var track = await Track.filledTrack
        await track.changeType(to: .speedtrap)
        await #expect(track.type == .speedtrap)
        
        await vm.receiveReplayTrackAction(.select(track))
        let receivedTrack = await vm.replayTrack
        #expect(track.id == receivedTrack?.id)
        
        let startCoordinate = try #require(track.points.first?.position)
        
        
        let location = CLLocation(coordinate: startCoordinate,
                                  altitude: 0,
                                  horizontalAccuracy: 1,
                                  verticalAccuracy: 1,
                                  course: 0,
                                  speed: 20,
                                  timestamp: .now)
        
        await vm.receivedLocationUpdate(location)
        #expect(trackService.startedTrack)
    }
    
    /*
     send location
     if we are outside start point nothing should happen
         */
    
    @Test("Speedtrap selection wrong location should not start")
    func testSpeedtrapTrackWrongLocationNotStarting() async throws {
        let trackService = TrackStartDetectMock()
        let vm = await BaseMapViewModel(dependencies: .mock(trackService: trackService))
        
        var track = await Track.filledTrack
        await track.changeType(to: .speedtrap)
        await #expect(track.type == .speedtrap)
        
        await vm.receiveReplayTrackAction(.select(track))
        let receivedTrack = await vm.replayTrack
        #expect(track.id == receivedTrack?.id)
        
        let startCoordinate = try #require(track.points.first?.position)
        
        
        let location = CLLocation(coordinate: startCoordinate.offsetToNorth(by: 500),
                                  altitude: 0,
                                  horizontalAccuracy: 1,
                                  verticalAccuracy: 1,
                                  course: 0,
                                  speed: 20,
                                  timestamp: .now)

        await vm.receivedLocationUpdate(location)
       #expect(trackService.startedTrack == false)
    }
    
    /*
     start Track recording
     send location
     if we are inside stop point track recording should stop
         */
     
}

