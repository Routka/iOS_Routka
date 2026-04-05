import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

/// A curated client for the Routka log backend.
///
/// `LogServiceClient` wraps the generated OpenAPI client and exposes app-facing request and
/// response models. Use it when you want a typed API for uploading logs and querying stored logs,
/// devices, and sessions.
///
/// Example:
/// ```swift
/// import Foundation
/// import LogService
///
/// let client = LogServiceClient(
///     serverURL: URL(string: "https://logs.example.com")!
/// )
///
/// let page = try await client.listDevices()
/// print(page.items.count)
/// ```
public struct LogServiceClient: LogServiceClientProtocol {
    private let underlyingClient: any APIProtocol

    /// Creates a client backed by the generated OpenAPI `Client`.
    ///
    /// - Parameters:
    ///   - serverURL: Base URL of the log backend.
    ///   - transport: OpenAPI transport used to perform requests. Defaults to `URLSessionTransport()`.
    ///
    /// Example:
    /// ```swift
    /// let client = LogServiceClient(
    ///     serverURL: URL(string: "http://localhost:8080")!
    /// )
    /// ```
    public init(
        serverURL: URL = URL(string: "http://localhost:8080")!,
        transport: any ClientTransport = URLSessionTransport()
    ) {
        self.underlyingClient = Client(
            serverURL: serverURL,
            transport: transport
        )
    }

    init(
        underlyingClient: any APIProtocol
    ) {
        self.underlyingClient = underlyingClient
    }

    /// Uploads logs using one of the supported payload formats from the OpenAPI document.
    ///
    /// Supported payloads:
    /// - `.single`: one JSON log object
    /// - `.batch`: an array of JSON log objects
    /// - `.gzippedJSON`: precompressed gzip data
    ///
    /// Example:
    /// ```swift
    /// let log = CreateAppLogRequest(
    ///     sessionID: "session-123",
    ///     deviceID: "device-456",
    ///     action: "paywall_opened",
    ///     creationDate: .now,
    ///     appVersion: "1.4.2",
    ///     deviceType: "iPhone16,2",
    ///     region: "US",
    ///     locale: "en_US",
    ///     type: "info",
    ///     category: "navigation"
    /// )
    ///
    /// try await client.createLogs(.single(log))
    /// ```
    public func createLogs(_ payload: LogsUploadPayload) async throws {
        let response: Operations.CreateLogs.Output

        switch payload {
        case let .single(log):
            let generatedLog = try bridge(log, to: Components.Schemas.CreateAppLog.self)
            response = try await underlyingClient.createLogs(body: .json(.CreateAppLog(generatedLog)))
        case let .batch(logs):
            let generatedLogs = try logs.map { try bridge($0, to: Components.Schemas.CreateAppLog.self) }
            response = try await underlyingClient.createLogs(body: .json(.case2(generatedLogs)))
        case let .gzippedJSON(data):
            response = try await underlyingClient.createLogs(body: .applicationGzip(HTTPBody(data)))
        }

        switch response {
        case .created:
            return
        case let .badRequest(badRequest):
            let error = try bridge(badRequest.body.json, to: LogServiceErrorResponse.self)
            throw LogServiceClientError.unexpectedStatusCode(400, reason: error.reason)
        case let .contentTooLarge(contentTooLarge):
            let error = try bridge(contentTooLarge.body.json, to: LogServiceErrorResponse.self)
            throw LogServiceClientError.unexpectedStatusCode(413, reason: error.reason)
        case let .undocumented(statusCode, _):
            throw LogServiceClientError.unexpectedStatusCode(statusCode, reason: nil)
        }
    }

    /// Uploads a single log entry as `application/json`.
    ///
    /// Example:
    /// ```swift
    /// let log = CreateAppLogRequest(
    ///     sessionID: "session-123",
    ///     deviceID: "device-456",
    ///     action: "track_started",
    ///     creationDate: .now,
    ///     appVersion: "1.4.2",
    ///     deviceType: "iPhone16,2",
    ///     region: "US",
    ///     locale: "en_US",
    ///     type: "info",
    ///     category: "tracking"
    /// )
    ///
    /// try await client.createLog(log)
    /// ```
    public func createLog(_ log: CreateAppLogRequest) async throws {
        try await createLogs(.single(log))
    }

    /// Uploads multiple log entries as a JSON array.
    ///
    /// Example:
    /// ```swift
    /// try await client.createLogs([
    ///     firstLog,
    ///     secondLog,
    /// ])
    /// ```
    public func createLogs(_ logs: [CreateAppLogRequest]) async throws {
        try await createLogs(.batch(logs))
    }

    /// Uploads gzip-compressed JSON data using `application/gzip`.
    ///
    /// Use this when the payload has already been serialized and compressed elsewhere.
    ///
    /// Example:
    /// ```swift
    /// let compressedPayload: Data = ...
    /// try await client.createCompressedLogs(compressedPayload)
    /// ```
    public func createCompressedLogs(_ data: Data) async throws {
        try await createLogs(.gzippedJSON(data))
    }

    /// Fetches logs for exactly one filter.
    ///
    /// Example:
    /// ```swift
    /// let page = try await client.listLogs(
    ///     filter: .deviceID("device-456"),
    ///     pagination: .init(limit: 50, offset: 0)
    /// )
    ///
    /// print(page.items.first?.action ?? "")
    /// ```
    public func listLogs(
        filter: LogsFilter,
        pagination: LogPagination = .init()
    ) async throws -> LogPage<AppLogModel> {
        let response: Operations.ListLogs.Output

        switch filter {
        case let .deviceID(deviceID):
            response = try await underlyingClient.listLogs(
                query: .init(
                    limit: pagination.limit,
                    offset: pagination.offset,
                    deviceID: deviceID,
                    sessionID: nil
                )
            )
        case let .sessionID(sessionID):
            response = try await underlyingClient.listLogs(
                query: .init(
                    limit: pagination.limit,
                    offset: pagination.offset,
                    deviceID: nil,
                    sessionID: sessionID
                )
            )
        }

        switch response {
        case let .ok(ok):
            return try bridge(ok.body.json, to: LogPage<AppLogModel>.self)
        case let .badRequest(badRequest):
            let error = try bridge(badRequest.body.json, to: LogServiceErrorResponse.self)
            throw LogServiceClientError.unexpectedStatusCode(400, reason: error.reason)
        case let .undocumented(statusCode, _):
            throw LogServiceClientError.unexpectedStatusCode(statusCode, reason: nil)
        }
    }

    /// Fetches the known devices page from the backend.
    ///
    /// Example:
    /// ```swift
    /// let devices = try await client.listDevices(
    ///     pagination: .init(limit: 100, offset: 0)
    /// )
    /// ```
    public func listDevices(
        pagination: LogPagination = .init()
    ) async throws -> LogPage<AppDeviceModel> {
        let response = try await underlyingClient.listDevices(
            query: .init(limit: pagination.limit, offset: pagination.offset)
        )

        switch response {
        case let .ok(ok):
            return try bridge(ok.body.json, to: LogPage<AppDeviceModel>.self)
        case let .badRequest(badRequest):
            let error = try bridge(badRequest.body.json, to: LogServiceErrorResponse.self)
            throw LogServiceClientError.unexpectedStatusCode(400, reason: error.reason)
        case let .undocumented(statusCode, _):
            throw LogServiceClientError.unexpectedStatusCode(statusCode, reason: nil)
        }
    }

    /// Fetches sessions for a specific device.
    ///
    /// Example:
    /// ```swift
    /// let sessions = try await client.listSessions(
    ///     forDeviceID: "device-456",
    ///     pagination: .init(limit: 100, offset: 0)
    /// )
    /// ```
    public func listSessions(
        forDeviceID deviceID: String,
        pagination: LogPagination = .init()
    ) async throws -> LogPage<AppSessionModel> {
        let response = try await underlyingClient.listSessionsForDevice(
            path: .init(deviceID: deviceID),
            query: .init(limit: pagination.limit, offset: pagination.offset)
        )

        switch response {
        case let .ok(ok):
            return try bridge(ok.body.json, to: LogPage<AppSessionModel>.self)
        case let .badRequest(badRequest):
            let error = try bridge(badRequest.body.json, to: LogServiceErrorResponse.self)
            throw LogServiceClientError.unexpectedStatusCode(400, reason: error.reason)
        case let .undocumented(statusCode, _):
            throw LogServiceClientError.unexpectedStatusCode(statusCode, reason: nil)
        }
    }

    private func bridge<Input: Encodable, Output: Decodable>(_ input: Input, to type: Output.Type) throws -> Output {
        let data = try makeEncoder().encode(input)
        return try makeDecoder().decode(type, from: data)
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(Self.decodeFlexibleDate)
        return decoder
    }

    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom(Self.encodeDate)
        return encoder
    }

    private static func encodeDate(_ date: Date, encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(makePlainDateFormatter().string(from: date))
    }

    private static func decodeFlexibleDate(from decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()

        if let stringValue = try? container.decode(String.self) {
            if let date = makeFractionalDateFormatter().date(from: stringValue)
                ?? makePlainDateFormatter().date(from: stringValue)
            {
                return date
            }
        }

        if let intValue = try? container.decode(Int64.self) {
            return date(fromUnixValue: Double(intValue))
        }

        if let doubleValue = try? container.decode(Double.self) {
            return date(fromUnixValue: doubleValue)
        }

        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported date value.")
    }

    private static func date(fromUnixValue value: Double) -> Date {
        let seconds = value > 10_000_000_000 ? value / 1_000 : value
        return Date(timeIntervalSince1970: seconds)
    }

    private static func makePlainDateFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }

    private static func makeFractionalDateFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }
}
