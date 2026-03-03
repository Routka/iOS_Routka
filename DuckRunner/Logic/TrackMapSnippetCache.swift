//
//  TrackMapSnippetCache.swift
//  DuckRunner
//
//  Created by vladukha on 18.02.2026.
//

import Foundation
import UIKit



protocol CacheFileManagerProtocol: Actor {
    func fileExists(atPath path: String) -> Bool
    func contents(atPath path: String) -> Data?
    func createFile(atPath path: String, contents data: Data?, attributes attr: [Data.WritingOptions]?)
    func removeItem(atPath path: String)
    func fileNames(atPath path: String, containing substring: String) -> [String]
}


final actor CacheFileManager: CacheFileManagerProtocol {
    let cacheFileManagerLogger = MainLogger("CacheFileManager")
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func fileExists(atPath path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }

    func contents(atPath path: String) -> Data? {
        fileManager.contents(atPath: path)
    }

    func createFile(
        atPath path: String,
        contents data: Data?,
        attributes attr: [Data.WritingOptions]?
    ) {
        guard let data else { return }

        let url = URL(fileURLWithPath: path)

        do {
            try fileManager.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            try data.write(to: url, options: [.atomic])
        } catch {
            cacheFileManagerLogger.log("Failed to write cache file ",
                                       message: "at \(path): \(error)",
                                       .error)
        }
    }

    func removeItem(atPath path: String) {
        try? fileManager.removeItem(atPath: path)
    }

    func fileNames(atPath path: String, containing substring: String) -> [String] {
        do {
            let names = try fileManager.contentsOfDirectory(atPath: path)
            if substring.isEmpty {
                return names
            }
            return names.filter { $0.contains(substring) }
        } catch {
            cacheFileManagerLogger.log("Failed to list directory",
                                       message: "at \(path): \(error)",
                                       .error)
            return []
        }
    }
}


protocol TrackMapSnippetCacheProtocol {
    func getSnippet(for track: Track, size: CGSize) async -> UIImage?
    func cacheSnippet(_ snippet: UIImage, for track: Track, size: CGSize) async
    func invalidateCache(for trackID: String) async
}

actor TrackMapSnippetCache: TrackMapSnippetCacheProtocol {
    private let fileManager: any CacheFileManagerProtocol
    
    init(fileManager: any CacheFileManagerProtocol) {
        self.fileManager = fileManager
    }
    
    private func path(for trackID: String, size: CGSize) -> String {
        return (NSTemporaryDirectory() as NSString).appendingPathComponent("trackmapcache-\(trackID)-\(size.width)-\(size.height).png")
    }
    
    func invalidateCache(for trackID: String) async {
        for image in await fileManager.fileNames(atPath: NSTemporaryDirectory(), containing: "trackmapcache-\(trackID)") {
            await fileManager.removeItem(atPath: (NSTemporaryDirectory() as NSString).appendingPathComponent(image))
        }
    }
    
    func getSnippet(for track: Track, size: CGSize) async -> UIImage? {
        let trackID = track.id
        let filePath = path(for: trackID, size: size)
        guard await fileManager.fileExists(atPath: filePath) else {
            return nil
        }
        guard let data = await fileManager.contents(atPath: filePath) else {
            return nil
        }
        return UIImage(data: data)
    }
    
    func cacheSnippet(_ snippet: UIImage, for track: Track, size: CGSize) async {
        let trackID = track.id
        let filePath = path(for: trackID, size: size)
        guard let data = snippet.pngData() else { return }
        await fileManager.createFile(atPath: filePath, contents: data, attributes: [.atomic])
    }
}

