//
//  TrackMapSnippetCache.swift
//  Routka
//
//  Created by vladukha on 18.02.2026.
//

import Foundation
import UIKit


nonisolated let trackMapSnippetCacheLogger = MainLogger("TrackMapSnippetCache")


protocol CacheFileManagerProtocol: Actor {
    func fileExists(atPath path: String) -> Bool
    func contents(atPath path: String) -> Data?
    func createFile(atPath path: String, contents data: Data?, attributes attr: [Data.WritingOptions]?)
    func removeItem(atPath path: String)
    func fileNames(atPath path: String, containing substring: String) -> [String]
    func removeAllTrackMapCacheFiles() async
}


final actor CacheFileManager: CacheFileManagerProtocol {
    let cacheFileManagerLogger = MainLogger("CacheFileManager")
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        cacheFileManagerLogger.log("Initialized", .info)
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
        do {
            try fileManager.removeItem(atPath: path)
        } catch {
            cacheFileManagerLogger.log("Failed to remove cache file",
                                       message: "at \(path): \(error)",
                                       .error)
        }
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
    
    func removeAllTrackMapCacheFiles() async {
        let allFiles = fileNames(atPath: NSTemporaryDirectory(), containing: "trackmapcache")
        for file in allFiles {
            removeItem(atPath: (NSTemporaryDirectory() as NSString).appendingPathComponent(file))
        }
        cacheFileManagerLogger.log("Removed all cache files",
                                   message: "count: \(allFiles.count)",
                                   .info)
    }
}


protocol TrackMapSnippetCacheProtocol {
    func getSnippet(for track: Track, size: CGSize) async -> UIImage?
    func cacheSnippet(_ snippet: UIImage, for track: Track, size: CGSize) async
    func invalidateCache(for trackID: String) async
    func removeAllCacheFiles() async
}

actor TrackMapSnippetCache: TrackMapSnippetCacheProtocol {
    private let fileManager: any CacheFileManagerProtocol
    
    init(fileManager: any CacheFileManagerProtocol) {
        self.fileManager = fileManager
        trackMapSnippetCacheLogger.log("Initialized", .info)
    }
    
    private func path(for trackID: String, size: CGSize) -> String {
        return (NSTemporaryDirectory() as NSString).appendingPathComponent("trackmapcache-\(trackID)-\(size.width)-\(size.height).png")
    }
    
    func invalidateCache(for trackID: String) async {
        let images = await fileManager.fileNames(atPath: NSTemporaryDirectory(), containing: "trackmapcache-\(trackID)")
        for image in images {
            await fileManager.removeItem(atPath: (NSTemporaryDirectory() as NSString).appendingPathComponent(image))
        }
        trackMapSnippetCacheLogger.log("Invalidated cache",
                                       message: "trackID: \(trackID), removed: \(images.count)",
                                       .info)
    }
    
    func getSnippet(for track: Track, size: CGSize) async -> UIImage? {
        let trackID = track.id
        let filePath = path(for: trackID, size: size)
        guard await fileManager.fileExists(atPath: filePath) else {
            trackMapSnippetCacheLogger.log("Cache miss",
                                           message: "trackID: \(trackID), size: \(Int(size.width))x\(Int(size.height))",
                                           .warning,
                                           silent: true)
            return nil
        }
        guard let data = await fileManager.contents(atPath: filePath) else {
            trackMapSnippetCacheLogger.log("Cache file unreadable",
                                           message: "trackID: \(trackID), path: \(filePath)",
                                           .warning)
            return nil
        }
        trackMapSnippetCacheLogger.log("Cache hit",
                                       message: "trackID: \(trackID), size: \(Int(size.width))x\(Int(size.height))",
                                       .info,
                                       silent: true)
        return UIImage(data: data)
    }
    
    func cacheSnippet(_ snippet: UIImage, for track: Track, size: CGSize) async {
        let trackID = track.id
        let filePath = path(for: trackID, size: size)
        guard let data = snippet.pngData() else {
            trackMapSnippetCacheLogger.log("Failed encoding cache snippet",
                                           message: "trackID: \(trackID)",
                                           .error)
            return
        }
        await fileManager.createFile(atPath: filePath, contents: data, attributes: [.atomic])
        trackMapSnippetCacheLogger.log("Cached snippet",
                                       message: "trackID: \(trackID), size: \(Int(size.width))x\(Int(size.height))",
                                       .info)
    }
    
    func removeAllCacheFiles() async {
        await fileManager.removeAllTrackMapCacheFiles()
        trackMapSnippetCacheLogger.log("Requested full cache cleanup", .info)
    }
}
