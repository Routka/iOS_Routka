//
//  TrackFileService.swift
//  Routka
//
//  Created by vladukha on 08.03.2026.
//

import Foundation
import SwiftUI

enum TrackFileServiceError: Error {
    case invalidFile
}

protocol TrackFileServiceProtocol: Observable {
    var isImporterPresented: Bool { get set }
    var isExporterPresented: Bool { get set }
    var fileToExport: URL? { get set }
    @discardableResult
    func importFromFile(url: URL) async throws -> Track
    func exportTrack(_ track: Track)
    func showImporter()
}

@Observable
final class TrackFileService: TrackFileServiceProtocol {
    
    private weak var trackStorage: (any TrackStorageProtocol)?
    
    init(trackStorage: any TrackStorageProtocol) {
        self.trackStorage = trackStorage
    }
    
    var isImporterPresented = false
    var isExporterPresented = false
    var fileToExport: URL?
    
    func showImporter() {
        self.isImporterPresented = true
    }
    
    @discardableResult
    func importFromFile(url: URL) async throws -> Track {
        guard url.pathExtension.lowercased() == "routka" else { throw TrackFileServiceError.invalidFile}
        do {
            let data = try Data(contentsOf: url)
            var track = try JSONDecoder().decode(Track.self, from: data)
            track.trackType = .import // override so it is always considered an import
            try await trackStorage?.addTrack(track)
            return track
        } catch {
            print("Failed to import .routka file: \(error)")
            // TODO: Record error to metric
            throw error
        }
    }
    
    func exportTrack(_ track: Track) {
        if let url = self.exportTrackToFile(track: track) {
            self.isExporterPresented = true
            self.fileToExport = url
        }
    }
    
    func exportTrackToFile(track: Track) -> URL? {
        do {
            let data = try JSONEncoder().encode(track)
            let filename = "Track_\(track.id).routka"
            let tempDirectory = FileManager.default.temporaryDirectory
            let fileURL = tempDirectory.appendingPathComponent(filename)
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            print("Failed to export .routka file: \(error)")
            return nil
        }
    }
    
}
