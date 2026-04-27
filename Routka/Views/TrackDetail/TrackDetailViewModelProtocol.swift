//
//  TrackDetailViewModelProtocol.swift
//  Routka
//

import SwiftUI
import MapKit

protocol TrackDetailViewModelProtocol: Observable {
    var showReplayButton: Bool { get }
    var showEditSection: Bool { get }
    var showDeleteTrackButton: Bool { get }
    var showReplaysSection: Bool { get }
    var showExportButton: Bool { get }
    var showModeEditButton: Bool { get }
    var showTrimButton: Bool { get }

    var averageSpeed: CLLocationSpeed? { get set }
    var parentTrack: Track? { get set }
    var children: [Track] { get set }
    var track: Track { get }
    var mapSnippet: MapSnippetComponent { get }

    func openOriginalRoute()
    func openChildTrack(_ child: Track)
    func exportTrack()
    func deleteTrack()
    func openTrackMap()
    func openTrackTrim()
    func replayTrack()
    func updateTrackType(to type: ReplayMode) async
    func calculateAverageSpeed()
}
