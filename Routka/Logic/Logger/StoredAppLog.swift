//
//  StoredAppLog.swift
//  Routka
//
//  Created by vladukha on 27.02.2026.
//

import Foundation
import SwiftData
import LogService

/// SwiftData-backed log record mirroring `CreateAppLogRequest` fields
@Model
final class StoredAppLog {
    @Attribute(.unique) var id: String
    var sessionID: String
    var deviceID: String
    var message: String?
    var action: String
    var creationDate: Date
    var appVersion: String
    var deviceType: String
    var region: String
    var locale: String
    var type: String
    var category: String

    init(
        id: String = UUID().uuidString,
        sessionID: String,
        deviceID: String,
        message: String? = nil,
        action: String,
        creationDate: Date,
        appVersion: String,
        deviceType: String,
        region: String,
        locale: String,
        type: String,
        category: String
    ) {
        self.id = id
        self.sessionID = sessionID
        self.deviceID = deviceID
        self.message = message
        self.action = action
        self.creationDate = creationDate
        self.appVersion = appVersion
        self.deviceType = deviceType
        self.region = region
        self.locale = locale
        self.type = type
        self.category = category
    }

    convenience init(_ record: CreateAppLogRequest) {
        self.init(
            id: record.id,
            sessionID: record.sessionID,
            deviceID: record.deviceID,
            message: record.message,
            action: record.action,
            creationDate: record.creationDate,
            appVersion: record.appVersion,
            deviceType: record.deviceType,
            region: record.region,
            locale: record.locale,
            type: record.type,
            category: record.category
        )
    }

    var record: CreateAppLogRequest {
        .init(
            id: id,
            sessionID: sessionID,
            deviceID: deviceID,
            message: message,
            action: action,
            creationDate: creationDate,
            appVersion: appVersion,
            deviceType: deviceType,
            region: region,
            locale: locale,
            type: type,
            category: category
        )
    }
}
