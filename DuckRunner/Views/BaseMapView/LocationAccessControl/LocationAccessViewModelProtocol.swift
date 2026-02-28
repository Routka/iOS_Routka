//
//  BaseMapViewModelProtocol.swift
//  DuckRunner
//
//  Created by vladukha on 25.02.2026.
//

import Foundation
import SwiftUI
import CoreLocation

/// Protocol defining the required interface for asking location and showing current location
protocol LocationAccessViewModelProtocol: Observable {
    var locationAccess: CLAuthorizationStatus { get }
    /// Try to request location authorization
    func requestLocation()
}

