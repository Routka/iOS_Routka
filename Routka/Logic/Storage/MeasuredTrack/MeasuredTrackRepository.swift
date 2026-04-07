//
//  MeasuredTrackRepository.swift
//  Routka
//
//  Created by vladukha on 04.03.2026.
//
import Foundation
import CoreData
import os
import Combine

let measuredTrackRepositoryLogger = MainLogger("MeasuredTrackRepository")

final class MeasuredTrackRepository: MeasuredTrackStorageProtocol {
    /// Publishes storage actions (creation, deletion, update) to notify observers of changes.
    var actionPublisher: PassthroughSubject<MeasuredTrackStorageAction, Never> = .init()
    
    /// Sends a storage action event through the publisher.
    internal func sendAction(_ action: MeasuredTrackStorageAction) {
        actionPublisher.send(action)
    }
    
    /// Initializes the repository with a Core Data container.
    init() {
        self.container = publicContainer
        measuredTrackRepositoryLogger.log("Initialized", .info)
    }
    
    /// The NSPersistentContainer managing Core Data storage.
    private var container: NSPersistentContainer
    
    /// Background context for performing storage operations.
    lazy var backgroundContext: NSManagedObjectContext = {
        let newbackgroundContext = container.newBackgroundContext()
        newbackgroundContext.automaticallyMergesChangesFromParent = true
        return newbackgroundContext
    }()

    func getMeasuredTracks(limit: Int?) async -> [MeasuredTrack] {
        let context: NSManagedObjectContext = self.backgroundContext
        return await withCheckedContinuation { continuation in
            context.performAndWait {
                
                let request: NSFetchRequest<MeasuredTrackDTO> = MeasuredTrackDTO.fetchRequest()
                if let limit {
                    request.fetchLimit = limit
                }
                do {
                    let measuredTrackDTOs = try context.fetch(request)

                    let measuredTracks: [MeasuredTrack] = measuredTrackDTOs
                        .compactMap { dto in
                            let track = MeasuredTrack(dto)
                            guard dto.track != nil else {
                                context.delete(dto)
                                self.sendAction(.deleted(track))
                                measuredTrackRepositoryLogger.log("Removed orphaned measured track",
                                                                  message: "id: \(track.id)",
                                                                  .warning)
                                return nil
                            }
                            return track
                        }
                    if context.hasChanges {
                        do {
                            try context.save()
                        } catch {
                            measuredTrackRepositoryLogger.log("Failed deleting orphaned measured tracks",
                                                              message: error.localizedDescription,
                                                              .error)
                        }
                    }
                    measuredTrackRepositoryLogger.log("Fetched measured tracks",
                                                      message: "count: \(measuredTracks.count), limit: \(limit?.description ?? "none")",
                                                      .info)
                    continuation.resume(returning: measuredTracks)
                } catch {
                    measuredTrackRepositoryLogger.log("Failed fetching measured tracks",
                                                      message: error.localizedDescription,
                                                      .error)
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    func addMeasuredTrack(_ track: MeasuredTrack) async {
        let context: NSManagedObjectContext = self.backgroundContext
        return await withCheckedContinuation { continuation in
            context.performAndWait {
             
                // Creating the record
                let _ = MeasuredTrackDTO(context: context, track)
                if context.hasChanges {
                    do {
                        try context.save()
                        self.sendAction(.created(track))
                        measuredTrackRepositoryLogger.log("Stored measured track",
                                                          message: "id: \(track.id), name: \(track.measurement.name)",
                                                          .info)
                    } catch {
                        measuredTrackRepositoryLogger.log("Failed saving measured track",
                                                          message: error.localizedDescription,
                                                          .error)
                    }
                }
                continuation.resume()
            }
        }
    }
    
    func deleteMeasuredTrack(_ track: MeasuredTrack) async {
        let context: NSManagedObjectContext = self.backgroundContext
        await withCheckedContinuation { continuation in
            context.performAndWait {
                let request = MeasuredTrackDTO.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", track.id)
                do {
                    if let item = try context.fetch(request).first {
                        context.delete(item)
                        if context.hasChanges {
                            try context.save()
                            self.sendAction(.deleted(track))
                            measuredTrackRepositoryLogger.log("Deleted measured track",
                                                              message: "id: \(track.id)",
                                                              .info)
                        }
                    } else {
                        measuredTrackRepositoryLogger.log("Delete skipped",
                                                          message: "No measured track found for id \(track.id)",
                                                          .warning)
                    }
                } catch {
                    measuredTrackRepositoryLogger.log("Failed deleting measured track",
                                                      message: error.localizedDescription,
                                                      .error)
                }
                continuation.resume()
            }
        }
    }
    
    func getShortestMeasuredTrack(named name: String) async -> MeasuredTrack? {
        let context: NSManagedObjectContext = self.backgroundContext
        return await withCheckedContinuation { continuation in
            context.performAndWait {
                let request: NSFetchRequest<MeasuredTrackDTO> = MeasuredTrackDTO.fetchRequest()
                request.predicate = NSPredicate(format: "name == %@", name)
                do {
                    let dtos = try context.fetch(request)
                    // Map to models, dropping orphans (and cleaning them up)
                    var tracks: [MeasuredTrack] = []
                    var didDelete = false
                    for dto in dtos {
                        let model = MeasuredTrack(dto)
                        if dto.track == nil {
                            context.delete(dto)
                            self.sendAction(.deleted(model))
                            didDelete = true
                            continue
                        }
                        tracks.append(model)
                    }
                    if didDelete, context.hasChanges {
                        do {
                            try context.save()
                        } catch {
                            measuredTrackRepositoryLogger.log("Failed saving measured track cleanup",
                                                              message: error.localizedDescription,
                                                              .error)
                        }
                    }
                    // Compute shortest by duration
                    let shortest = tracks.min(by: { lhs, rhs in
                        let ld = (lhs.track.stopDate ?? lhs.track.startDate).timeIntervalSince(lhs.track.startDate)
                        let rd = (rhs.track.stopDate ?? rhs.track.startDate).timeIntervalSince(rhs.track.startDate)
                        return ld < rd
                    })
                    measuredTrackRepositoryLogger.log("Resolved shortest measured track",
                                                      message: "name: \(name), found: \(shortest != nil), count: \(tracks.count)",
                                                      .info)
                    continuation.resume(returning: shortest)
                } catch {
                    measuredTrackRepositoryLogger.log("Failed fetching measured tracks by name",
                                                      message: error.localizedDescription,
                                                      .error)
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
