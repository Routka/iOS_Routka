//
//  MapSnippetView.swift
//  DuckRunner
//
//  Created by vladukha on 03.03.2026.
//

import SwiftUI

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
            .onAppear {
                print("SNIPPER FOR \(track.id) APPEARED")
            }
            .onDisappear {
                print("SNIPPER FOR \(track.id) DISSAPEARED")
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
                            guard mapSnippetImage == nil else {
                                print("CANCELED")
                                return }
                            imageLoadingTask = Task {
                                if let cachedImage = await mapSnippetCache.getSnippet(for: track, size: geo.size) {
                                    guard !Task.isCancelled else {
                                        print("CANCELED")
                                        return }
                                    await MainActor.run {
                                        withAnimation {
                                            self.mapSnippetImage = cachedImage
                                        }
                                    }
                                } else {
                                    guard !Task.isCancelled else {
                                        print("CANCELED")
                                        return }
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

#Preview {
    MapSnippetView(mapSnippetCache: DependencyManager.MockTrackMapSnippetCache(),
                   mapSnapshotGenerator: MapSnapshotGenerator(),
                   track: .filledTrack)
}
