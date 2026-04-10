//
//  LogSenderService.swift
//  Routka
//
//  Created by vladukha on 06.04.2026.
//

import Foundation
import Combine
import UIKit
import LogService

final class LogService {
    private var cancellables: Set<AnyCancellable> = []
    public static let shared: LogService = .init()
    private let logRepo: any LogStorageProtocol = LogStorage.shared
    private let logSender = LogServiceClient(serverURL: URL(string: "https://routka.com")!)
    
    private let version: String
    private let build: String
    private let deviceType: String
    private let region: String
    private let locale: String
    private let deviceID: String
    private let sessionID: String
    

    // Отдельный форматтер при работе с зарубежными календарями (например Буддистский)
    private let moscowTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        // Set Gregorian calendar
        formatter.calendar = Calendar(identifier: .gregorian)
        // Set Moscow timezone
        formatter.timeZone = TimeZone(identifier: "Europe/Moscow")
        
        formatter.dateFormat = "dd.MM.yyyy HH:mm:ss.SSS z"
        
        return formatter
    }()
    
    private init() {
        self.version = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "Failed Version"
        self.build = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "Failed Build"
        self.deviceType = {
            var systemInfo = utsname()
            uname(&systemInfo)
            let modelCode = withUnsafePointer(to: &systemInfo.machine) {
                $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                    ptr in String.init(validatingUTF8: ptr)
                }
            }
            return modelCode ?? "Unknown model"
        } ()
        self.region = Locale.current.region?.identifier ?? "Failed Region"
        self.locale = Locale.current.identifier
        self.deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "Unknown identifier, is device unlocked?"
        self.sessionID = UUID().uuidString
        self.setupLifecycleListeners()
        #if PRODUCTION
        self.startCycle()
        #endif
    }
    
    private func setupLifecycleListeners() {
            let notificationCenter = NotificationCenter.default

            // Publisher for app lifecycle notifications
            let lifecyclePublisher = Publishers.MergeMany(
                notificationCenter.publisher(for: UIApplication.willResignActiveNotification)
                    .map { _ in "Will Resign Active" },
                notificationCenter.publisher(for: UIApplication.didBecomeActiveNotification)
                    .map { _ in "Did Become Active" },
                notificationCenter.publisher(for: UIApplication.didEnterBackgroundNotification)
                    .map { _ in "Did Enter Background" },
                notificationCenter.publisher(for: UIApplication.willEnterForegroundNotification)
                    .map { _ in "Will Enter Foreground" }
            )

            // Subscribe to lifecycle changes
            lifecyclePublisher
                .sink { status in
                    mainLogger.log("App lifecycle changed: \(status)", .info)
                }
                .store(in: &cancellables)
        }
    
    /// Записывает лог в кордата на его отправку на сервер
    func registerLog(action: String,
                     message: String?,
                     type: String,
                     creationDate: Date,
                     category: String,
                     source: String) async {
        // Capture needed values up front to avoid capturing self inside the Task
        let sessionID = self.sessionID
        let deviceID = self.deviceID
        let appVersion = "v\(self.version) (\(self.build))"
        let deviceType = self.deviceType
        let region = self.region
        let locale = self.locale
        
        do {
            try await logRepo.addLog(.init(id: UUID().uuidString,
                                           sessionID: sessionID,
                                           deviceID: deviceID,
                                           message: message,
                                           action: action,
                                           source: source,
                                           creationDate: creationDate,
                                           appVersion: appVersion,
                                           deviceType: deviceType,
                                           region: region,
                                           locale: locale,
                                           _type: type,
                                           category: category))
        } catch {
            print("Failed creating log: \(error)")
        }
    }
    
    private func startCycle() {
        Task {
            while true {
                do {
                    try await self.cycle()
                } catch {
                    print("Failed sending logs attempt: \(error)")
                    try? await Task.sleep(for: .seconds(5))
                }
            }
        }
    }
    
    private func cycle() async throws {
        let logs = try await logRepo.fetchOldestLogs(limit: 50)
        guard logs.isEmpty == false else {
            try? await Task.sleep(for: .seconds(5))
            return
        }
        let _ = try await logSender.createLogs(logs)
        print("logs sent", logs.count)
        try? await logRepo.deleteLogs(ids: logs.map(\.id))
    }
}
