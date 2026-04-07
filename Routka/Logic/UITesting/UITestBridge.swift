//
//  UITestBridge.swift
//  Routka
//
//  Created by Codex on 14.08.2025.
//

import Foundation

enum UITestBridge {
    static let suiteName = "group.com.vladukha.routka.uitest"

    enum Key {
        static let locationCommand = "uitest.location.command"
        static let trackStorageCommand = "uitest.trackStorage.command"
        static let measuredTrackStorageCommand = "uitest.measuredTrackStorage.command"
    }

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }
}

struct ScriptedLocationCommand: Codable, Equatable {
    enum Action: String, Codable {
        case loadScenario
        case start
        case pause
        case stop
        case reset
    }

    let id: UUID
    let action: Action
    let scenario: Track?
    let sentAt: Date
}

struct SeededTrackStorageCommand: Codable, Equatable {
    enum Action: String, Codable {
        case loadScenario
        case reset
    }

    let id: UUID
    let action: Action
    let scenarioName: String?
    let sentAt: Date
}

struct SeededMeasuredTrackStorageCommand: Codable, Equatable {
    enum Action: String, Codable {
        case loadScenario
        case reset
    }

    let id: UUID
    let action: Action
    let scenarioName: String?
    let sentAt: Date
}

@MainActor
final class UITestCommandReceiver<Command: Decodable> {
    private let key: String
    private let interval: TimeInterval
    private let onCommand: (Command) -> Void
    private var timer: Timer?
    private var lastPayload: Data?

    init(
        key: String,
        interval: TimeInterval = 0.25,
        onCommand: @escaping (Command) -> Void
    ) {
        self.key = key
        self.interval = interval
        self.onCommand = onCommand
    }

    func start() {
        self.consumeIfNeeded()
        self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.consumeIfNeeded()
            }
        }
    }

    func stop() {
        self.timer?.invalidate()
        self.timer = nil
    }

    private func consumeIfNeeded() {
        guard let defaults = UITestBridge.defaults,
              let payload = defaults.data(forKey: key),
              payload != lastPayload,
              let command = try? JSONDecoder().decode(Command.self, from: payload)
        else {
            return
        }

        self.lastPayload = payload
        self.onCommand(command)
    }
}
