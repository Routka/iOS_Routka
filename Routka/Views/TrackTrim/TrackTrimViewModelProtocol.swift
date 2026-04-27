//
//  TrackTrimViewModelProtocol.swift
//  Routka
//

import SwiftUI

protocol TrackTrimViewModelProtocol: Observable {
    var track: Track { get }
    var trimmedTrack: Track { get set }
    var startIndex: Int { get set }
    var stopIndex: Int { get set }
    var maxCount: Int { get }
    var mapMode: MapViewMode { get }
    var locationService: any LocationServiceProtocol { get }

    func saveCurrent()
    func saveAsNewTrack()
}
