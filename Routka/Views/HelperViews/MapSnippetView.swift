//
//  MapSnippetView.swift
//  Routka
//
//  Created by vladukha on 03.03.2026.
//

import SwiftUI
import NeedleFoundation

protocol MapSnippetDependency: Dependency {
    var mapSnippetCache: any TrackMapSnippetCacheProtocol { get }
    var mapSnapshotGenerator: any MapSnapshotGeneratorProtocol { get }
}

nonisolated
final class MapSnippetComponent: Component<MapSnippetDependency> {
    private let track: Track
    
    init(parent: Scope, track: Track) {
        self.track = track
        super.init(parent: parent)
    }
    
    @MainActor
    var mapSnippet: some View {
        MapSnippetView(mapSnippetCache: dependency.mapSnippetCache,
                       mapSnapshotGenerator: dependency.mapSnapshotGenerator,
                       track: track)
    }
}

struct MapSnippetView: View {
    let mapSnippetCache: any TrackMapSnippetCacheProtocol
    let mapSnapshotGenerator: any MapSnapshotGeneratorProtocol
    let track: Track
    
    @State private var imageLoadingTask: Task<Void, Never>? = nil
    
    func generateMapImage(size: CGSize) async {
        guard let image = try? await mapSnapshotGenerator
            .generateSnapshot(track: track, size: size) else {
            return
        }
        guard !Task.isCancelled else { return }
        await MainActor.run {
            withAnimation {
                self.mapSnippetImage = image
            }
        }
        await mapSnippetCache.cacheSnippet(image,
                                           for: track,
                                           size: size)
    }
    
    var body: some View {
        mapSnippet
            .onDisappear {
                self.mapSnippetImage = nil
                self.imageLoadingTask?.cancel()
            }
    }
    
    @State private var mapSnippetImage: UIImage?
    private var mapSnippet: some View {
        SkeletonImage()
            .background {
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            guard mapSnippetImage == nil else { return }
                            imageLoadingTask = Task {
                                if let cachedImage = await mapSnippetCache.getSnippet(for: track, size: geo.size) {
                                    guard !Task.isCancelled else { return }
                                    await MainActor.run {
                                        withAnimation {
                                            self.mapSnippetImage = cachedImage
                                        }
                                    }
                                } else {
                                    guard !Task.isCancelled else { return }
                                    await generateMapImage(size: geo.size)
                                }
                            }
                        }
                }
            }
            .overlay(content: {
                if let mapSnippetImage {
                    Image(uiImage: mapSnippetImage)
                        .resizable()
                        .scaledToFit()
                        .transition(.opacity)
                }
            })
    }
}

nonisolated
class MockMapSnippetParentComponent: BootstrapComponent {
    
    @MainActor
    public var mapSnippetCache: any TrackMapSnippetCacheProtocol {
        DependencyManager.MockTrackMapSnippetCache()
    }
    @MainActor
    public var mapSnapshotGenerator: any MapSnapshotGeneratorProtocol {
        MapSnapshotGenerator()
    }
    
    
    @MainActor
    var mapComponent: MapSnippetComponent {
        MapSnippetComponent(parent: self, track: .filledTrack)
    }
}

#Preview {
    Group {
        let component = MockMapSnippetParentComponent()
        return component.mapComponent.mapSnippet
    }
}
