//
//  FavouritesRepository.swift
//  DuckRunner
//
//  Created by vladukha on 16.02.2026.
//


import Foundation
import CoreData
import os
import Combine

let publicContainer = {
    let container = NSPersistentContainer(name: "CoreDataStorage")
    container.loadPersistentStores { _, error in
        if let error {
            print("Failed loading container", error)
        }
    }
    return container
}()

/// Repository for persistent storage and retrieval of tracks using Core Data.
/// Implements TrackStorageProtocol for CRUD operations and action publishing.
final class TrackRepository: TrackStorageProtocol {
    /// Publishes storage actions (creation, deletion, update) to notify observers of changes.
    var actionPublisher: PassthroughSubject<StorageAction, Never> = .init()
    
    /// Sends a storage action event through the publisher.
    internal func sendAction(_ action: StorageAction) {
        actionPublisher.send(action)
    }
    
    /// Initializes the repository with a Core Data container.
    init() {
        self.container = publicContainer
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
                    continuation.resume()
                    return
                }
                
                // Creating the record
                let _ = TrackDTO(context: context, track)
                if context.hasChanges {
                    try? context.save()
                    self.sendAction(.created(track))
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
                        }
                    }
                } catch {
                    print(error)
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
                        item.parentID = track.parentID
                        item.type = track.type.rawValue
                        if context.hasChanges {
                            try context.save()
                            self.sendAction(.updated(track))
                        }
                    }
                } catch {
                    print(error)
                }
                continuation.resume()
            }
        }
    }
    
    /// Retrieves all tracks from storage, sorted by start date.
    func getAllTracks() async -> [Track] {
        let context = self.backgroundContext
        return await withCheckedContinuation { [context] continuation in
            context.performAndWait {
                
                let request = TrackDTO.fetchRequest()
                
                request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
                
                do {
                    let items = try context.fetch(request)
                    let dtos = items.compactMap { Track($0) }
                    continuation.resume(returning: dtos)
                } catch {
                    print(error)
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    /// Retrieves tracks that start on a specific date.
    func getTracks(for date: Date) async -> [Track] {
        let context = self.backgroundContext
        return await withCheckedContinuation { [context] continuation in
            context.performAndWait {
                
                let request: NSFetchRequest<TrackDTO> = TrackDTO.fetchRequest()
                let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
                request.predicate = NSPredicate(format: "startDate >= %@ && startDate <= %@",
                                                Calendar.current.startOfDay(for: date) as NSDate,
                                                Calendar.current.startOfDay(for: nextDay) as NSDate)
                request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
                let tracks = (try? context.fetch(request)) ?? []
                continuation.resume(returning: tracks.map({Track($0)}))
            }
        }
    }
    
    /// Retrieves tracks that have specific parent
    func getTracks(withParentID parent: String) async -> [Track] {
        let context = self.backgroundContext
        return await withCheckedContinuation { [context] continuation in
            context.performAndWait {
                
                let request: NSFetchRequest<TrackDTO> = TrackDTO.fetchRequest()
                request.predicate = NSPredicate(format: "parentID == %@", parent)
                
                let tracks = (try? context.fetch(request)) ?? []
                continuation.resume(returning: tracks.map({Track($0)}))
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
                let tracks = (try? context.fetch(request)) ?? []
                if let track = tracks.first {
                    continuation.resume(returning: Track(track))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
