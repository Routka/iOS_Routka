//
//  MeasuredTrackListViewModelProtocol.swift
//  DuckRunner
//
//  Created by vladukha on 04.03.2026.
//
import SwiftUI

protocol MeasuredTrackListViewModelProtocol: Observable {
    var tracks: [MeasuredTrack] { get }
}
