import Foundation

public struct LogPagination: Sendable, Hashable, Codable {
    public let limit: Int
    public let offset: Int

    public init(limit: Int = 100, offset: Int = 0) {
        self.limit = limit
        self.offset = offset
    }
}

public enum LogsFilter: Sendable, Hashable, Codable {
    case deviceID(String)
    case sessionID(String)
}

public enum LogsUploadPayload: Sendable, Hashable {
    case single(CreateAppLogRequest)
    case batch([CreateAppLogRequest])
    case gzippedJSON(Data)
}

public struct CreateAppLogRequest: Sendable, Hashable, Codable {
    public let sessionID: String
    public let deviceID: String
    public let message: String?
    public let action: String
    public let creationDate: Date
    public let appVersion: String
    public let deviceType: String
    public let region: String
    public let locale: String
    public let type: String
    public let category: String

    public init(
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
}

public struct AppLogModel: Sendable, Hashable, Codable {
    public let id: UUID?
    public let sessionID: String
    public let deviceID: String
    public let message: String?
    public let action: String
    public let creationDate: Date
    public let appVersion: String
    public let deviceType: String
    public let region: String
    public let locale: String
    public let type: String
    public let category: String
}

public struct AppDeviceModel: Sendable, Hashable, Codable {
    public let id: UUID?
    public let deviceID: String
    public let lastDeviceType: String
    public let lastAppVersion: String
    public let lastRegion: String
    public let lastLocale: String
    public let lastSeenAt: Date
}

public struct AppSessionModel: Sendable, Hashable, Codable {
    public let id: UUID?
    public let sessionID: String
    public let deviceID: String
    public let firstLogAt: Date
    public let lastLogAt: Date
}

public struct LogPage<Item: Sendable & Hashable & Codable>: Sendable, Hashable, Codable {
    public let items: [Item]
    public let total: Int
    public let limit: Int
    public let offset: Int
}

public struct LogServiceErrorResponse: Sendable, Hashable, Codable, Error {
    public let error: Bool?
    public let reason: String?

    public init(error: Bool? = nil, reason: String? = nil) {
        self.error = error
        self.reason = reason
    }
}

public enum LogServiceClientError: LocalizedError {
    case unexpectedStatusCode(Int, reason: String?)
    case invalidResponse
    case missingResponseBody

    public var errorDescription: String? {
        switch self {
        case let .unexpectedStatusCode(statusCode, reason):
            return reason ?? "The log service returned HTTP \(statusCode)."
        case .invalidResponse:
            return "The log service returned an invalid response."
        case .missingResponseBody:
            return "The log service response body was empty."
        }
    }
}

public protocol LogServiceClientProtocol {
    func createLogs(_ payload: LogsUploadPayload) async throws
    func createLog(_ log: CreateAppLogRequest) async throws
    func createLogs(_ logs: [CreateAppLogRequest]) async throws
    func createCompressedLogs(_ data: Data) async throws
    func listLogs(
        filter: LogsFilter,
        pagination: LogPagination
    ) async throws -> LogPage<AppLogModel>
    func listDevices(
        pagination: LogPagination
    ) async throws -> LogPage<AppDeviceModel>
    func listSessions(
        forDeviceID deviceID: String,
        pagination: LogPagination
    ) async throws -> LogPage<AppSessionModel>
}
