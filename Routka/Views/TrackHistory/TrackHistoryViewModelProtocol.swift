//
//  TrackHistoryViewModelProtocol.swift
//  Routka
//
//  Created by vladukha on 16.02.2026.
//

import SwiftUI
import Combine

/// A view model protocol that provides track history data and manages the selected date for filtering.
/// 
/// Conforming types supply an array of tracks filtered by the selected date and allow the date to be changed.
protocol TrackHistoryViewModelProtocol: Observable {
    /// The tracks to display, typically filtered by the selected date.
    var state: ListState<Track> { get }
    
    /// The currently selected date for viewing track history.
    var selectedDate: Date { get set }
    
    func openTrack(_ track: Track)
    func trackCell(_ track: Track, unitSpeed: UnitSpeed) -> TrackHistoryCellComponent
}
