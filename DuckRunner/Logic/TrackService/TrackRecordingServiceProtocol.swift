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
    var stopPolicy: RecordingAutoStopPolicy { get }
    func clearTrack()
    @discardableResult
    func appendTrackPosition(_ point: TrackPoint) throws(TrackServiceError) -> SuggestedRecordingAction
    func startTrack(_ stopPolicy: RecordingAutoStopPolicy)
    @discardableResult
    func stopTrack() throws(TrackServiceError) -> Track
}
