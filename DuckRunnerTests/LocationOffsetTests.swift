//
//  LocationOffsetTests.swift
//  DuckRunnerTests
//
//  Created by vladukha on 22.02.2026.
//

import Testing
import CoreLocation
@testable import DuckRunner

struct LocationOffsetTests {

    @Test("Test location offset to the north", arguments: [
        0,
        1,
        2,
        3,
        10,
        15,
        100,
        -5,
        -10
    ])
    func testOffset(_ meters: Int) async throws {
        let initialCoordinate: CLLocationCoordinate2D = await Track.filledTrack.points.first!.position
        
        let movedCoordinate = initialCoordinate.offsetToNorth(by: CLLocationDistance(meters))
        
        let initialLocation: CLLocation = .init(latitude: initialCoordinate.latitude, longitude: initialCoordinate.longitude)
        let movedLocation: CLLocation = .init(latitude: movedCoordinate.latitude, longitude: movedCoordinate.longitude)
        #expect(Int(initialLocation.distance(from: movedLocation)) == abs(meters))
        
    }

}
