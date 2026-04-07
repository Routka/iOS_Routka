//
//  FavouritesRepository.swift
//  Routka
//
//  Created by vladukha on 16.02.2026.
//


import Foundation
import CoreData
import os
import Combine

let trackRepositoryLogger = MainLogger("TrackRepository")

let publicContainer = {
    let container = NSPersistentContainer(name: "CoreDataStorage")
    container.persistentStoreDescriptions.forEach {
        $0.shouldMigrateStoreAutomatically = true
        $0.shouldInferMappingModelAutomatically = true
    }
    container.loadPersistentStores { _, error in
        if let error {
            trackRepositoryLogger.log("Failed loading container", message: "\(error)", .error)
        }
    }
    return container
}()

/// Repository for persistent storage and retrieval of tracks using Core Data.
/// Implements TrackStorageProtocol for CRUD operations and action publishing.
final class TrackRepository: TrackStorageProtocol {
    /// Publishes storage actions (creation, deletion, update) to notify observers of changes.
    var actionPublisher: PassthroughSubject<TrackStorageAction, Never> = .init()
    
    /// Sends a storage action event through the publisher.
    internal func sendAction(_ action: TrackStorageAction) {
        actionPublisher.send(action)
    }
    
    /// Initializes the repository with a Core Data container.
    init() {
        self.container = publicContainer
        trackRepositoryLogger.log("Initialized", .info)
    }
    
    /// The NSPersistentContainer managing Core Data storage.
    private var container: NSPersistentContainer
    
    /// Background context for performing storage operations.
    lazy var backgroundContext: NSManagedObjectContext = {
        let newbackgroundContext = container.newBackgroundContext()
        newbackgroundContext.automaticallyMergesChangesFromParent = true
        return newbackgroundContext
    }()
    
    /// Adds a new track to persistent storage if it does not already exist.
    func addTrack(_ track: Track) async {
        
        let context = self.backgroundContext
        return await withCheckedContinuation { [context] continuation in
            context.performAndWait {
                let request = TrackDTO.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", track.id)
                request.fetchLimit = 1
                let existingFav = (try? context.fetch(request)) ?? []
                if existingFav.first != nil {
                    // track already exists, so we return it and exit the continuation
                    trackRepositoryLogger.log("Skipped adding track",
                                              message: "Track already exists with id \(track.id)",
                                              .warning)
                    continuation.resume()
                    return
                }
                
                // Creating the record
                let _ = TrackDTO(context: context, track)
                if context.hasChanges {
                    do {
                        try context.save()
                        self.sendAction(.created(track))
                        trackRepositoryLogger.log("Stored track",
                                                  message: "id: \(track.id), points: \(track.points.count)",
                                                  .info)
                    } catch {
                        trackRepositoryLogger.log("Failed saving created track",
                                                  message: error.localizedDescription,
                                                  .error)
                    }
                }
                continuation.resume()
            }
        }
    }

    /// Deletes a track from persistent storage by its identifier.
    func deleteTrack(_ track: Track) async {
        let context = self.backgroundContext
        await withCheckedContinuation { [context, track] continuation in
            context.performAndWait {
                let request = TrackDTO.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", track.id)
                do {
                    if let item = try context.fetch(request).first {
                        context.delete(item)
                        if context.hasChanges {
                            try context.save()
                            self.sendAction(.deleted(track))
                            trackRepositoryLogger.log("Deleted track", message: "id: \(track.id)", .info)
                        }
                    } else {
                        trackRepositoryLogger.log("Delete skipped",
                                                  message: "No stored track found for id \(track.id)",
                                                  .warning)
                    }
                } catch {
                    trackRepositoryLogger.log("Failed deleting the track", message: error.localizedDescription, .error)
                }
                continuation.resume()
            }
        }
    }
    
    /// Updates an existing track in persistent storage.
    func updateTrack(_ track: Track) async throws {
        let context = self.backgroundContext
        await withCheckedContinuation { [context, track] continuation in
            context.performAndWait {
                let request = TrackDTO.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", track.id)
                do {
                    if let item = try context.fetch(request).first {
                        item.points = NSSet(array: track.points.map({TrackPointDTO(context: context, $0)}))
                        item.custom_name = track.custom_name
                        item.parentID = track.parentID
                        item.trackType = track.trackType.rawValue
                        item.replayMode = track.replayMode.rawValue
                        item.startDate = track.startDate
                        if context.hasChanges {
                            try context.save()
                            self.sendAction(.updated(track))
                            trackRepositoryLogger.log("Updated track",
                                                      message: "id: \(track.id), points: \(track.points.count)",
                                                      .info)
                        }
                    } else {
                        trackRepositoryLogger.log("Update skipped",
                                                  message: "No stored track found for id \(track.id)",
                                                  .warning)
                    }
                } catch {
                    trackRepositoryLogger.log("Failed updating the track", message: error.localizedDescription, .error)
                }
                continuation.resume()
            }
        }
    }
    
    /// Retrieves all tracks from storage, sorted by start date.
    func getAllTracks(ofType trackType: TrackType = .record, limit: Int?) async -> [Track] {
        let context = self.backgroundContext
        return await withCheckedContinuation { [context] continuation in
            context.performAndWait {
                
                let request = TrackDTO.fetchRequest()
                request.predicate = NSPredicate(format: "trackType == %@", trackType.rawValue)
                request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
                if let limit {
                    request.fetchLimit = limit
                }
                do {
                    let items = try context.fetch(request)
                    let dtos = items.compactMap { Track($0) }
                    trackRepositoryLogger.log("Fetched tracks",
                                              message: "type: \(trackType.rawValue), count: \(dtos.count), limit: \(limit?.description ?? "none")",
                                              .info)
                    continuation.resume(returning: dtos)
                } catch {
                    trackRepositoryLogger.log("Failed fetching the tracks", message: error.localizedDescription, .error)
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    /// Retrieves tracks that start on a specific date.
    func getTracks(for date: Date, ofType trackType: TrackType = .record) async -> [Track] {
        let context = self.backgroundContext
        return await withCheckedContinuation { [context] continuation in
            context.performAndWait {
                
                let request: NSFetchRequest<TrackDTO> = TrackDTO.fetchRequest()
                let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
                let datePredicate = NSPredicate(format: "startDate >= %@ && startDate <= %@",
                                                Calendar.current.startOfDay(for: date) as NSDate,
                                                Calendar.current.startOfDay(for: nextDay) as NSDate)
                let measureNilPredicate = NSPredicate(format: "trackType == %@", trackType.rawValue)
                request.predicate = NSCompoundPredicate(type: .and, subpredicates: [datePredicate, measureNilPredicate])
                request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
                do {
                    let tracks = try context.fetch(request)
                    let models = tracks.map({ Track($0) })
                    trackRepositoryLogger.log("Fetched tracks for date",
                                              message: "date: \(date), type: \(trackType.rawValue), count: \(models.count)",
                                              .info)
                    continuation.resume(returning: models)
                } catch {
                    trackRepositoryLogger.log("Failed fetching tracks for date",
                                              message: error.localizedDescription,
                                              .error)
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    /// Retrieves tracks that have specific parent
    func getTracks(withParentID parent: String, ofType trackType: TrackType = .record) async -> [Track] {
        let context = self.backgroundContext
        return await withCheckedContinuation { [context] continuation in
            context.performAndWait {
                
                let request: NSFetchRequest<TrackDTO> = TrackDTO.fetchRequest()
                let parentPredicate = NSPredicate(format: "parentID == %@", parent)
                let measureNilPredicate = NSPredicate(format: "trackType == %@", trackType.rawValue)
                request.predicate = NSCompoundPredicate(type: .and, subpredicates: [parentPredicate, measureNilPredicate])

                do {
                    let tracks = try context.fetch(request)
                    let models = tracks.map({ Track($0) })
                    trackRepositoryLogger.log("Fetched tracks by parent",
                                              message: "parentID: \(parent), type: \(trackType.rawValue), count: \(models.count)",
                                              .info)
                    continuation.resume(returning: models)
                } catch {
                    trackRepositoryLogger.log("Failed fetching tracks by parent",
                                              message: error.localizedDescription,
                                              .error)
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    /// Retrieves track by id
    func getTrack(by id: String) async -> Track? {
        let context = self.backgroundContext
        return await withCheckedContinuation { [context] continuation in
            context.performAndWait {
                
                let request: NSFetchRequest<TrackDTO> = TrackDTO.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", id)
                request.fetchLimit = 1
                do {
                    let tracks = try context.fetch(request)
                    if let track = tracks.first {
                        trackRepositoryLogger.log("Fetched track by id", message: "id: \(id)", .info)
                        continuation.resume(returning: Track(track))
                    } else {
                        trackRepositoryLogger.log("Track not found", message: "id: \(id)", .warning)
                        continuation.resume(returning: nil)
                    }
                } catch {
                    trackRepositoryLogger.log("Failed fetching track by id",
                                              message: error.localizedDescription,
                                              .error)
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
