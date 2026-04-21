//
//  TracksTabViewModel.swift
//  Routka
//
//  Created by vladukha on 08.03.2026.
//
import SwiftUI
import Combine

@Observable
final class TracksTabViewModel: TracksTabViewModelProtocol {
    func openTrack(_ track: Track) {
        let trackDetailRoute = component.trackDetailComponent(track: track).route
        routers[tabRouter.selectedTab]?.push(trackDetailRoute)
    }
    
    
    func trackHistoryCellComponent(track: Track, unitSpeed: UnitSpeed) -> TrackHistoryCellComponent {
        self.component.trackHistoryCell(track: track, unitSpeed: unitSpeed)
    }
    
    func openImportedTracks() {
        #warning("fix navigation")
//        .routers[tabRouter.selectedTab]?.push(
//            .importedTracks(vm: ImportedTracksListViewModel(dependencies: dependencies),
//                            dependencies: dependencies))
    }
    func openMeasuredTracks() {
#warning("fix navigation")
//        routers[tabRouter.selectedTab]?.push(
//            .measuredTracks(vm: MeasuredTrackListViewModel(dependencies: dependencies),
//                            dependencies: dependencies))
    }
    func openTrackHistory() {
#warning("fix navigation")
//        routers[tabRouter.selectedTab]?.push(
//            .trackHistory(vm: TrackHistoryViewModel(dependencies: dependencies),
//                          dependencies: dependencies))
    }
    func openMeasuredTrack(_ measure: MeasuredTrack) {
        let route = component.measuredtrackDetail(measuredTrack: measure).route
        routers[tabRouter.selectedTab]?.push(route)
    }
    func openMap() {
        tabRouter.selectedTab = "Map"
    }
    
    func showImporter() {
        trackFileService.showImporter()
    }
    
    let showLimit = 6
    
    var historyTracks: [Track] = []
    var measuredTracks: [MeasuredTrack] = []
    var importedTracks: [Track] = []
    
    private var cancellables: Set<AnyCancellable> = []
    private let tabRouter: any TabRouterProtocol
    private let routers: [String: Router]
    private let trackFileService: any TrackFileServiceProtocol
    private let component: TracksTabComponent
    
    init(storageService: any TrackStorageProtocol,
         measuredTrackStorageService: any MeasuredTrackStorageProtocol,
         tabRouter: any TabRouterProtocol,
         routers: [String: Router],
         trackFileService: any TrackFileServiceProtocol,
         component: TracksTabComponent) {
        self.component = component
        self.tabRouter = tabRouter
        self.routers = routers
        self.trackFileService = trackFileService
        Task {
            let historyTracks = await storageService
                .getAllTracks(ofType: .record, limit: showLimit)
            withAnimation {
                self.historyTracks = historyTracks
            }
        }
        Task {
            let importedTracks = await storageService
                .getAllTracks(ofType: .import, limit: showLimit)
            withAnimation {
                self.importedTracks = importedTracks
            }
        }
        
        Task {
            let measuredTracks = await measuredTrackStorageService
                .getMeasuredTracks(limit: showLimit)
            withAnimation {
                self.measuredTracks = measuredTracks
            }
        }
        
        storageService
            .actionPublisher
            .sink { [weak self] action in
                self?.receiveAction(action)
            }
            .store(in: &cancellables)
        measuredTrackStorageService
            .actionPublisher
            .sink { [weak self] action in
                self?.receiveAction(action)
            }
            .store(in: &cancellables)
    }
    
    private func receiveAction(_ action: MeasuredTrackStorageAction) {
        switch action {
        case .created(let track):
            guard measuredTracks.count < showLimit else { return }
            // Insert track by descending startDate order
            if let index = measuredTracks.firstIndex(where: { $0.startDate > track.startDate }) {
                measuredTracks.insert(track, at: index)
            } else {
                measuredTracks.insert(track, at: 0)
            }
        case .deleted(let track):
            measuredTracks.removeAll(where: { $0.id == track.id })
        case .updated(let track):
            if let index = measuredTracks.firstIndex(where: { $0.id == track.id }) {
                measuredTracks[index] = track
            }
        }
    }
    
    private func receiveAction(_ action: TrackStorageAction) {
        withAnimation {
            switch action {
            case .created(let track):
                switch track.trackType {
                case .record:
                    let index = self.historyTracks.firstIndex(where: { $0.startDate > track.startDate }) ?? 0
                    self.historyTracks.insert(track, at: index)
                    if historyTracks.count > showLimit {
                        self.historyTracks.removeLast(1)
                    }
                case .import:
                    let index = self.importedTracks.firstIndex(where: { $0.startDate > track.startDate }) ?? 0
                    self.importedTracks.insert(track, at: index)
                    if importedTracks.count > showLimit {
                        self.importedTracks.removeLast(1)
                    }
                case .measurement:
                    break
                }
                
            case .deleted(let track):
                self.historyTracks.removeAll(where: { $0.id == track.id })
                self.importedTracks.removeAll(where: { $0.id == track.id })
            case .updated(let track):
                if let index = self.historyTracks.firstIndex(where: { $0.id == track.id }) {
                    self.historyTracks[index] = track
                } else if let index = self.importedTracks.firstIndex(where: { $0.id == track.id }) {
                    self.importedTracks[index] = track
                }
            }
        }
    }
}
