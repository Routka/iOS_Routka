//
//  Track.swift
//  DuckRunner
//
//  Created by vladukha on 18.02.2026.
//

import Testing
import UIKit
@testable import DuckRunner

extension Track {
    init(id: String) {
        self.init(id: id, points: [])
    }
}
// Mock FileManager that allows us to control file presence and content
final actor MockFileManager: CacheFileManagerProtocol {
    func removeAllTrackMapCacheFiles() async {
    }
    
    func fileNames(atPath path: String, containing substring: String) -> [String] {
        return []
    }
    
    private let queue = DispatchQueue(label: "CacheFileManager.queue")
    var files: [String: Data] = [:]
    var writtenFiles: [(String, Data)] = []
    func fileExists(atPath path: String) -> Bool {
        return queue.sync { files[path] != nil }
    }
    
    func contents(atPath path: String) -> Data? {
        return queue.sync { files[path] }
    }
    
    func createFile(atPath path: String, contents data: Data?, attributes attr: [Data.WritingOptions]? ) {
        return queue.sync {
            guard let d = data else { return }
            files[path] = d
            writtenFiles.append((path, d))
        }
    }
    
    func removeItem(atPath path: String) {
        queue.sync {
            let _ = files.removeValue(forKey: path)
        }
    }
    
    func applyFiles(key: String, data: Data) {
        self.files[key] = data
    }
}

@Suite("TrackMapSnippetCache Tests")
struct TrackMapSnippetCacheTests {
    // Helper
    func makeImage() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 2, height: 2), false, 1)
        UIColor.red.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: 2, height: 2))
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return img
    }
    
    @Test("Cache miss returns nil")
    func cacheMissReturnsNil() async throws {
        let fm = MockFileManager()
        let cache = await TrackMapSnippetCache(fileManager: fm)
        let image = await cache.getSnippet(for: Track(id: "A"), size: CGSize(width: 10, height: 10))
        #expect(image == nil)
    }
    
    @Test("Cache hit returns stored image")
    func cacheHitReturnsImage() async throws {
        let fm = MockFileManager()
        let img = makeImage()
        let data = img.pngData()!
        let track = Track(id: "B")
        let size = CGSize(width: 10, height: 11)
        let fakePath = (NSTemporaryDirectory() as NSString).appendingPathComponent("trackmapcache-B-10.0-11.0.png")
        await fm.applyFiles(key: fakePath, data: data)
        let cache = await TrackMapSnippetCache(fileManager: fm)
        let result = await cache.getSnippet(for: track, size: size)
        #expect(result != nil)
    }
    
    @Test("cacheSnippet writes file")
    func cacheWritesFile() async throws {
        let fm = MockFileManager()
        let cache = await TrackMapSnippetCache(fileManager: fm)
        let img = makeImage()
        let track = Track(id: "C")
        let size = CGSize(width: 12, height: 12)
        await cache.cacheSnippet(img, for: track, size: size)
        let fakePath = (NSTemporaryDirectory() as NSString).appendingPathComponent("trackmapcache-C-12.0-12.0.png")
        await #expect(fm.files[fakePath] != nil)
    }
    
    @Test("Different tracks/sizes do not collide")
    func differentKeysDoNotCollide() async throws {
        let fm = MockFileManager()
        let cache = await TrackMapSnippetCache(fileManager: fm)
        let img1 = makeImage()
        let img2 = makeImage()
        let t1 = Track(id: "A")
        let t2 = Track(id: "B")
        await cache.cacheSnippet(img1, for: t1, size: CGSize(width: 8, height: 9))
        await cache.cacheSnippet(img2, for: t2, size: CGSize(width: 8, height: 9))
        let path1 = (NSTemporaryDirectory() as NSString).appendingPathComponent("trackmapcache-A-8.0-9.0.png")
        let path2 = (NSTemporaryDirectory() as NSString).appendingPathComponent("trackmapcache-B-8.0-9.0.png")
        await #expect(fm.files[path1] != nil)
        await #expect(fm.files[path2] != nil)
    }

}
