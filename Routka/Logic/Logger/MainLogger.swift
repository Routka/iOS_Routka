//
//  MainLogger.swift
//  Routka
//
//  Created by vladukha on 03.03.2026.
//

import Foundation
import os

/// Логгер который добавляет лог в системный Logger
public final actor MainLogger {
    
    enum LogType: String {
        case info
        case error
        case warning
    }
    
    private let category: String
    private let logger: Logger
    struct LoggerResponse: Codable {
        let id: String
    }
    
    init(_ category: String) {
        self.category = category
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: category)
    }
    
    nonisolated func log(_ action: String,
                         message: String? = nil,
                         _ type: LogType,
                         silent: Bool = false,
                         function: StaticString = #function,
                         file: StaticString  = #file,
                         line: UInt  = #line) {
        let date = Date()
        Task.detached { [weak self] in
            guard let self else { return }
            await self.logAsync(action, message: message, date: date, type, silent: silent, function: function, file: file, line: line)
        }
    }
    
    private func logAsync(_ action: String,
                          message: String? = nil,
                          date: Date,
                          _ type: LogType,
                          silent: Bool = false,
                          function: StaticString = #function,
                          file: StaticString  = #file,
                          line: UInt  = #line) async {
        
        let fileName = URL(string: "\(file)")?.lastPathComponent.replacingOccurrences(of: ".swift", with: "")
        
        self.logger.log("\(action) \(message ?? "-", privacy: .public)\nfile: \(fileName ?? ""), function: \(function), line: \(line)")
        await LogService.shared.registerLog(action: action + "\nfile: \(fileName ?? ""), function: \(function), line: \(line)",
                                            message: message,
                                            type: type.rawValue,
                                            creationDate: date,
                                            category: self.category)
    }
}
