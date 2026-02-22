//
//  CodingKeys.swift
//  DuckRunner
//
//  Created by vladukha on 18.02.2026.
//
import Foundation
import CoreLocation

extension CLLocationCoordinate2D: @retroactive nonisolated Codable {
    /// Codable conformance for CLLocationCoordinate2D enabling serialization.
    enum CodingKeys: String, CodingKey {
        case longitude
        case latitude
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try values.decode(Double.self, forKey: .latitude)
        let longitude = try values.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.latitude, forKey: .latitude)
        try container.encode(self.longitude, forKey: .longitude)
    }
    
    
}


extension CLLocationCoordinate2D: @retroactive nonisolated Hashable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(longitude)
        hasher.combine(latitude)
    }
}


extension CLLocationCoordinate2D {
    public mutating func offsettingToNorth(by meters: CLLocationDistance) {
        // Length in km of 1° of latitude = always 111.32 km
        let deltaLat = meters / 111_132.0
        self.latitude += deltaLat
    }
    
    public func offsetToNorth(by meters: CLLocationDistance) -> Self {
        // Length in km of 1° of latitude = always 111.32 km
        let deltaLat = meters / 111_132.0
        return CLLocationCoordinate2D(latitude: self.latitude + deltaLat, longitude: self.longitude)
    }
}
