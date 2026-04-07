//
//  LogStorage.swift
//  Routka
//
//  Created by vladukha on 27.02.2026.
//

import Foundation
import SwiftData
import LogService

protocol LogStorageProtocol: AnyObject {
    func addLog(_ log: CreateAppLog) async throws
    func deleteLog(id: String) async throws
    func deleteLogs(ids: [String]) async throws
    func fetchOldestLogs(limit: Int) async throws -> [CreateAppLog]
}

actor LogStorage: LogStorageProtocol {
    public static let shared: LogStorage = .init()
    private let container: ModelContainer

    private init(container: ModelContainer = LogStorage.makeContainer()) {
        self.container = container
    }

    func addLog(_ log: CreateAppLog) async throws {
        let context = ModelContext(container)
        context.insert(StoredAppLog(log))
        try context.save()
    }

    func deleteLog(id: String) async throws {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<StoredAppLog>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1

        if let log = try context.fetch(descriptor).first {
            context.delete(log)
            try context.save()
        }
    }

    func deleteLogs(ids: [String]) async throws {
        guard !ids.isEmpty else {
            return
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<StoredAppLog>(
            predicate: #Predicate { ids.contains($0.id) }
        )
        let logs = try context.fetch(descriptor)

        guard !logs.isEmpty else {
            return
        }

        for log in logs {
            context.delete(log)
        }

        try context.save()
    }

    func fetchOldestLogs(limit: Int = 50) async throws -> [CreateAppLog] {
        var descriptor = FetchDescriptor<StoredAppLog>(
            sortBy: [SortDescriptor(\.creationDate, order: .forward)]
        )
        descriptor.fetchLimit = max(limit, 0)
        let context = ModelContext(container)
        return try context.fetch(descriptor).map(\.record)
    }
}

private nonisolated extension LogStorage {
    static func makeContainer() -> ModelContainer {
        let schema = Schema([
            StoredAppLog.self,
        ])

        do {
            return try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to create LogStorage ModelContainer: \(error)")
        }
    }
}
