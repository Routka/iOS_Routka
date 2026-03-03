//
//  TrackServiceProtocol.swift
//  DuckRunner
//
//  Created by vladukha on 15.02.2026.
//


import Combine
import Foundation

protocol TrackRecordingServiceProtocol: Observable {
    var isRecording: Bool { get }
    var currentTrack: Track? { get }
    func clearTrack()
    func appendTrackPosition(_ point: TrackPoint) throws(TrackServiceError)
    func startTrack(at date: Date)
    @discardableResult
    func stopTrack(at date: Date) throws(TrackServiceError) -> Track
}
