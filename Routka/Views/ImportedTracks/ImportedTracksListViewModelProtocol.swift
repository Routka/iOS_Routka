//
//  ImportedTracksListViewModelProtocol.swift
//  Routka
//
//  Created by vladukha on 08.03.2026.
//
import SwiftUI

/// Protocol for the imported tracks list view model
protocol ImportedTracksListViewModelProtocol: Observable {
    var screenState: ListState<Track> { get }
    func openTrack(_ track: Track)
    func trackHistoryCell(_ track: Track, unitSpeed: UnitSpeed) -> TrackHistoryCellComponent
    func showImporter()
}
