//
//  TrackTrimViewModel.swift
//  Routka
//
//  Created by vladukha on 27.04.2026.
//

import SwiftUI
import Combine

@Observable
final class TrackTrimViewModel: TrackTrimViewModelProtocol {
    let track: Track
    var trimmedTrack: Track
    var startIndex: Int {
        didSet {
            self.trimTrack(startPoint: startIndex,
                           stopPoint: self.stopIndex)
//            startIndexPub.send(startIndex)
        }
    }
    var stopIndex: Int {
        didSet {
            self.trimTrack(startPoint: startIndex,
                           stopPoint: self.stopIndex)
//            startIndexPub.send(startIndex)
        }
    }
    let maxCount: Int
    
    let mapMode: MapViewMode
    
    private let startIndexPub = PassthroughSubject<Int, Never>()
    private let stopIndexPub = PassthroughSubject<Int, Never>()
    
    private var cancellables: Set<AnyCancellable> = []
    private let routing: any TrackTrimRouting
    private let storageService: any TrackStorageProtocol
    let locationService: any LocationServiceProtocol
    private let mapSnippetCache: any TrackMapSnippetCacheProtocol
    
    init(track: Track,
         storageService: any TrackStorageProtocol,
         routing: any TrackTrimRouting,
         locationService: any LocationServiceProtocol,
         mapSnippetCache: any TrackMapSnippetCacheProtocol) {
        self.track = track
        self.storageService = storageService
        self.routing = routing
        self.locationService = locationService
        self.mapMode = .free(track)
        self.mapSnippetCache = mapSnippetCache
        
        self.trimmedTrack = track
        self.startIndex = 0
        self.stopIndex = track.points.count - 1
        self.maxCount = track.points.count - 1
        
//        startIndexPub
//            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
//            .sink { newStartIndex in
//                self.trimTrack(startPoint: newStartIndex,
//                               stopPoint: self.stopIndex)
//            }
//            .store(in: &cancellables)
//        stopIndexPub
//            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
//            .sink { newStopIndex in
//                self.trimTrack(startPoint: self.startIndex,
//                          stopPoint: newStopIndex)
//            }
//            .store(in: &cancellables)
    }
    
    func saveCurrent() {
        Task {
            let track = self.trimmedTrack
            do {
                try await storageService.updateTrack(track)
                routing.pop()
                await mapSnippetCache.invalidateCache(for: track.id)
            } catch {
#warning("TODO: ALERT and log")
                print("Failed saving track", error)
            }
        }
    }
    
    func saveAsNewTrack() {
        Task {
            let NewTrack = Track(id: UUID().uuidString,
                                 points: trimmedTrack.points,
                              parentID: nil)
            do {
                try await storageService.addTrack(NewTrack)
                await routing.openNewTrack(NewTrack)
            } catch {
#warning("TODO: ALERT and log")
                print("Failed saving track", error)
            }
        }
    }
    
    private func trimTrack(startPoint: Int, stopPoint: Int) {
        let cut = track.points[startPoint...stopPoint]
        trimmedTrack.points = Array(cut)
    }
    
}
