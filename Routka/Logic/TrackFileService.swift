//
//  TrackFileService.swift
//  Routka
//
//  Created by vladukha on 08.03.2026.
//

import Foundation
import SwiftUI

let trackFileServiceLogger = MainLogger("TrackFileService")

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
        trackFileServiceLogger.log("Initialized", .info)
    }
    
    var isImporterPresented = false
    var isExporterPresented = false
    var fileToExport: URL?
    
    func showImporter() {
        self.isImporterPresented = true
        trackFileServiceLogger.log("Presented file importer", .info)
    }
    
    @discardableResult
    func importFromFile(url: URL) async throws -> Track {
        trackFileServiceLogger.log("Started importing track", message: "url: \(url.lastPathComponent)", .info)
        guard url.pathExtension.lowercased() == "routka" else {
            trackFileServiceLogger.log("Rejected file import",
                                       message: "Unsupported extension for \(url.lastPathComponent)",
                                       .warning)
            throw TrackFileServiceError.invalidFile
        }
        do {
            let data = try Data(contentsOf: url)
            var track = try JSONDecoder().decode(Track.self, from: data)
            track.trackType = .import // override so it is always considered an import
            try await trackStorage?.addTrack(track)
            trackFileServiceLogger.log("Imported track",
                                       message: "id: \(track.id), file: \(url.lastPathComponent)",
                                       .info)
            return track
        } catch {
            trackFileServiceLogger.log("Failed importing track",
                                       message: "file: \(url.lastPathComponent), error: \(error.localizedDescription)",
                                       .error)
            throw error
        }
    }
    
    func exportTrack(_ track: Track) {
        if let url = self.exportTrackToFile(track: track) {
            self.isExporterPresented = true
            self.fileToExport = url
            trackFileServiceLogger.log("Prepared track export",
                                       message: "id: \(track.id), file: \(url.lastPathComponent)",
                                       .info)
        } else {
            trackFileServiceLogger.log("Failed preparing track export",
                                       message: "id: \(track.id)",
                                       .error)
        }
    }
    
    func exportTrackToFile(track: Track) -> URL? {
        do {
            let data = try JSONEncoder().encode(track)
            let baseName = sanitizedFileName(for: track)
            let filename = "\(baseName).routka"
            let tempDirectory = FileManager.default.temporaryDirectory
            let fileURL = tempDirectory.appendingPathComponent(filename)
            try data.write(to: fileURL, options: .atomic)
            trackFileServiceLogger.log("Created export file",
                                       message: "id: \(track.id), file: \(filename)",
                                       .info)
            return fileURL
        } catch {
            trackFileServiceLogger.log("Failed exporting track",
                                       message: "id: \(track.id), error: \(error.localizedDescription)",
                                       .error)
            return nil
        }
    }

    private func sanitizedFileName(for track: Track) -> String {
        var customName: String
        if let source = track.custom_name?.trimmingCharacters(in: .whitespacesAndNewlines){
            let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
            let components = source.components(separatedBy: invalidCharacters)
            let sanitized = components.joined(separator: "_")
                .replacingOccurrences(of: "\n", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            customName = sanitized
        } else {
            customName = track.id
        }

        return customName
    }
    
}
