//
//  MKMapPoint Extension.swift
//  DuckRunner
//
//  Created by vladukha on 24.02.2026.
//
import MapKit

extension MKMapPoint: @retroactive Equatable {
    public static func == (lhs: MKMapPoint, rhs: MKMapPoint) -> Bool {
        lhs.coordinate == rhs.coordinate
    }
}
