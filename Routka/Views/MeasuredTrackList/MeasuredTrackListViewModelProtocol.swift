//
//  MeasuredTrackListViewModelProtocol.swift
//  Routka
//
//  Created by vladukha on 04.03.2026.
//
import SwiftUI

/// An interface for managing and deleting measured track lists.
protocol MeasuredTrackListViewModelProtocol: Observable {
    /// The list of measured tracks.
    var tracks: [MeasuredTrack] { get }
    
    /// Deletes measured tracks at the specified offsets.
    /// - Parameter offsets: The index set indicating which tracks to delete.
    func delete(at offsets: IndexSet) async
}
