//
//  XCUIDevice Extension.swift
//  Routka
//
//  Created by vladukha on 07.04.2026.
//
import XCTest
import CoreLocation

extension XCUIDevice {
    static func goTo(_ point: TrackPoint) {
        XCUIDevice.shared.location = XCUILocation(
            location:
                CLLocation.init(coordinate: .init(latitude: point.position.latitude, longitude: point.position.longitude),
                                altitude: 0,
                                horizontalAccuracy: 1,
                                verticalAccuracy: 1,
                                course: -1,
                                speed: point.speed,
                                timestamp: point.date)
        )
    }
}

struct Track: Decodable {
    let points: [TrackPoint]
}

struct TrackPoint: Decodable {
    let position: TrackCoordinate
    let speed: CLLocationSpeed
    let date: Date
}

struct TrackCoordinate: Decodable {
    let longitude: CLLocationDegrees
    let latitude: CLLocationDegrees
}

