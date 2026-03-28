//
//  TracksTabViewModelProtocol.swift
//  Routka
//
//  Created by vladukha on 08.03.2026.
//
import Foundation

protocol TracksTabViewModelProtocol: Observable {
    var showLimit: Int { get }
    var historyTracks: [Track] { get }
    var measuredTracks: [MeasuredTrack] { get }
    var importedTracks: [Track] { get }
}
