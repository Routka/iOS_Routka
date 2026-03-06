//
//  TrackRegionGenerator.swift
//  DuckRunner
//
//  Created by vladukha on 18.02.2026.
//

import Foundation
import CoreLocation
import MapKit

extension Array where Element == TrackPoint {
    /// Returns a map region of this track
    func regionOfATrack() -> MKCoordinateRegion {
        guard let firstPoint = self.first?.position else {
            return .init()
        }
        
        let bounds = self.reduce(
            into: (
                minLat: firstPoint.latitude,
                maxLat: firstPoint.latitude,
                minLon: firstPoint.longitude,
                maxLon: firstPoint.longitude
            )
        ) { result, point in
            result.minLat = Swift.min(result.minLat, point.position.latitude)
            result.maxLat = Swift.max(result.maxLat, point.position.latitude)
            result.minLon = Swift.min(result.minLon, point.position.longitude)
            result.maxLon = Swift.max(result.maxLon, point.position.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (bounds.minLat + bounds.maxLat) / 2,
            longitude: (bounds.minLon + bounds.maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta:  (bounds.maxLat - bounds.minLat) * 1.5,
            longitudeDelta: (bounds.maxLon - bounds.minLon) * 1.2
        )

        let region = MKCoordinateRegion(center: center, span: span)
        return region
    }
}
