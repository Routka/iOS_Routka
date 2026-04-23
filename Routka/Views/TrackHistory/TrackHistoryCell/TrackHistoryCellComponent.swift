//
//  TrackHistoryCellComponent.swift
//  Routka
//
//  Created by vladukha on 23.04.2026.
//


import NeedleFoundation
import Foundation

nonisolated
final class TrackHistoryCellComponent: Component<EmptyDependency> {
    private let track: Track
    private let unitSpeed: UnitSpeed
    init(parent: Scope,
         track: Track,
         unitSpeed: UnitSpeed) {
        self.track = track
        self.unitSpeed = unitSpeed
        super.init(parent: parent)
    }
    
    @MainActor
    var mapSnippet: MapSnippetComponent {
        MapSnippetComponent(parent: self, track: track)
    }
    
    @MainActor
    var view: TrackHistoryCellView {
        TrackHistoryCellView(track: track,
                             unit: unitSpeed,
                             mapSnippetComponent: mapSnippet)
    }
}

nonisolated
class TrackHistoryCellMockComponentProvider: BootstrapComponent {
    @MainActor
    public var mapSnippetCache: any TrackMapSnippetCacheProtocol {
        DependencyManager.MockTrackMapSnippetCache()
    }
    @MainActor
    public var mapSnapshotGenerator: any MapSnapshotGeneratorProtocol {
        MapSnapshotGenerator()
    }
    
    @MainActor
    func trackCell(track: Track, unit: UnitSpeed) -> TrackHistoryCellComponent {
        TrackHistoryCellComponent(parent: self, track: track, unitSpeed: unit)
    }
}
