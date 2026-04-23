//
//  SpeedBucket.swift
//  Routka
//
//  Created by vladukha on 18.02.2026.
//


import MapKit
/*
0-30 km/h - 0-8.333 m/s - синий какой нить максимально neutral apple
30-60km/h - 8.333-16.666 m/s - green
60-80 km/h - 16.666 - 22.222 m/s - yellow
80-110 km/h - 22.222 - 30.555 m/s - lava orange
110+ km/h - 30.555+m/s - red
*/

nonisolated
enum SpeedBucket: Equatable {
    case slow, regular, speedy, dangerous, extreme
    init(for speed: CLLocationSpeed) {
        switch speed {
        case ..<9:
            self = .slow
        case ..<17:
            self = .regular
        case ..<23:
            self = .speedy
        case ..<31:
            self = .dangerous
        default:
            self = .extreme
        }
    }
    
    func color() -> UIColor {
        switch self {
        case .slow:
            return .cyan
        case .regular:
            return .systemGreen
        case .speedy:
            return .yellow
        case .dangerous:
            return .orange
        case .extreme:
            return .red
        }
    }
}
