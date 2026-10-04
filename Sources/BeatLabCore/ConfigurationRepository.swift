import Foundation

/// One versioned, local payload. No audio/transport state is persisted here.
public struct ConfigurationRepository {
    public static let storageKey = "beatlab.metronome.configuration"
    public static let schemaVersion = 1
    private let defaults: UserDefaults

    public enum LoadStatus: Equatable {
        case new
        case restored
        case corrupt
        case unsupportedVersion(Int)
    }

    public struct LoadResult {
        public let configuration: MetronomeConfiguration
        public let status: LoadStatus
    }

    public enum PersistenceError: Error, Equatable {
        case unsupportedVersion(Int)
    }

    private struct Header: Decodable {
        let schemaVersion: Int
    }

    private struct Envelope: Codable {
        let schemaVersion: Int
        let configuration: MetronomeConfiguration
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> LoadResult {
        guard defaults.object(forKey: Self.storageKey) != nil else {
            return LoadResult(configuration: .defaultValue, status: .new)
        }
        guard let data = defaults.data(forKey: Self.storageKey) else {
            return LoadResult(configuration: .defaultValue, status: .corrupt)
        }
        do {
            let header = try JSONDecoder().decode(Header.self, from: data)
            guard header.schemaVersion == Self.schemaVersion else {
                return LoadResult(
                    configuration: .defaultValue,
                    status: .unsupportedVersion(header.schemaVersion)
                )
            }
            let payload = try JSONDecoder().decode(Envelope.self, from: data)
            return LoadResult(configuration: payload.configuration, status: .restored)
        } catch {
            return LoadResult(configuration: .defaultValue, status: .corrupt)
        }
    }

    public func save(_ configuration: MetronomeConfiguration) throws {
        // Recheck storage at the write boundary; another store cannot downgrade it.
        if case let .unsupportedVersion(version) = load().status {
            throw PersistenceError.unsupportedVersion(version)
        }
        let payload = Envelope(schemaVersion: Self.schemaVersion, configuration: configuration)
        let data = try JSONEncoder().encode(payload)
        defaults.set(data, forKey: Self.storageKey)
    }

    /// Called only by the user's explicit reset action, including future schemas.
    public func reset() {
        defaults.removeObject(forKey: Self.storageKey)
    }
}
