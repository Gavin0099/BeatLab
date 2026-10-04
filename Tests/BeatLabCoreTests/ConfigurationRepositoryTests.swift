import Foundation
import XCTest
@testable import BeatLabCore

final class ConfigurationRepositoryTests: XCTestCase {
    private func withDefaults(_ body: (UserDefaults, String) throws -> Void) throws {
        let suite = "BeatLabCoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        try body(defaults, suite)
    }

    func testMissingSettingsLoadSafeDefaultsWithoutWriting() throws {
        try withDefaults { defaults, _ in
            let result = ConfigurationRepository(defaults: defaults).load()
            XCTAssertEqual(result.status, .new)
            XCTAssertEqual(result.configuration, .defaultValue)
            XCTAssertNil(defaults.object(forKey: ConfigurationRepository.storageKey))
        }
    }

    func testRoundTripPersistsAllFourFieldsToNewRepository() throws {
        try withDefaults { defaults, suite in
            let config = try MetronomeConfiguration(
                tempo: Tempo(bpm: 137), timeSignature: .threeFour,
                subdivision: .sixteenth, accentEnabled: false
            )
            try ConfigurationRepository(defaults: defaults).save(config)
            let freshDefaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            let result = ConfigurationRepository(defaults: freshDefaults).load()
            XCTAssertEqual(result.status, .restored)
            XCTAssertEqual(result.configuration, config)
            let stored = try XCTUnwrap(defaults.data(forKey: ConfigurationRepository.storageKey))
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: stored) as? [String: Any])
            XCTAssertEqual(json["schemaVersion"] as? Int, 1)
        }
    }

    func testCompoundConfigurationRoundTrips() throws {
        try withDefaults { defaults, _ in
            let config = try MetronomeConfiguration(
                tempo: Tempo(bpm: 60), timeSignature: .sixEight,
                subdivision: .compoundEighth, accentEnabled: true
            )
            let repository = ConfigurationRepository(defaults: defaults)
            try repository.save(config)
            XCTAssertEqual(repository.load().configuration, config)
        }
    }

    func testCorruptAndInvalidStoredValuesReturnSafeDefaults() throws {
        try withDefaults { defaults, _ in
            let invalid: [Any] = [
                "unexpected storage type", Data("invalid JSON".utf8),
                Data(#"{"schemaVersion":1,"configuration":{"tempo":29,"timeSignature":"4/4","subdivision":"quarter","accentEnabled":true}}"#.utf8),
                Data(#"{"schemaVersion":1,"configuration":{"tempo":120,"timeSignature":"6/8","subdivision":"quarter","accentEnabled":true}}"#.utf8),
                Data(#"{"schemaVersion":1}"#.utf8)
            ]
            let repository = ConfigurationRepository(defaults: defaults)
            for value in invalid {
                defaults.set(value, forKey: ConfigurationRepository.storageKey)
                XCTAssertEqual(repository.load().status, .corrupt)
                XCTAssertEqual(repository.load().configuration, .defaultValue)
            }
        }
    }

    func testValidEditCanRecoverCorruptPayload() throws {
        try withDefaults { defaults, _ in
            defaults.set(Data("corrupt".utf8), forKey: ConfigurationRepository.storageKey)
            let repository = ConfigurationRepository(defaults: defaults)
            var config = MetronomeConfiguration.defaultValue
            config.setTempo(try Tempo(bpm: 100))
            try repository.save(config)
            XCTAssertEqual(repository.load().status, .restored)
            XCTAssertEqual(repository.load().configuration.tempo.bpm, 100)
        }
    }

    func testUnsupportedSchemaIsPreservedAndBlocksOverwrite() throws {
        try withDefaults { defaults, _ in
            let raw = Data(#"{"schemaVersion":2,"futureValue":"keep this"}"#.utf8)
            defaults.set(raw, forKey: ConfigurationRepository.storageKey)
            let repository = ConfigurationRepository(defaults: defaults)
            XCTAssertEqual(repository.load().status, .unsupportedVersion(2))
            XCTAssertEqual(repository.load().configuration, .defaultValue)
            XCTAssertThrowsError(try repository.save(.defaultValue)) {
                XCTAssertEqual($0 as? ConfigurationRepository.PersistenceError, .unsupportedVersion(2))
            }
            XCTAssertEqual(defaults.data(forKey: ConfigurationRepository.storageKey), raw)
        }
    }

    func testSaveRechecksSchemaAtWriteBoundary() throws {
        try withDefaults { defaults, _ in
            let repository = ConfigurationRepository(defaults: defaults)
            XCTAssertEqual(repository.load().status, .new)
            let future = Data(#"{"schemaVersion":3}"#.utf8)
            defaults.set(future, forKey: ConfigurationRepository.storageKey)
            XCTAssertThrowsError(try repository.save(.defaultValue))
            XCTAssertEqual(defaults.data(forKey: ConfigurationRepository.storageKey), future)
        }
    }

    func testExplicitResetAllowsFreshSaveAfterUnsupportedSchema() throws {
        try withDefaults { defaults, _ in
            defaults.set(Data(#"{"schemaVersion":2}"#.utf8), forKey: ConfigurationRepository.storageKey)
            let repository = ConfigurationRepository(defaults: defaults)
            repository.reset()
            XCTAssertEqual(repository.load().status, .new)
            try repository.save(.defaultValue)
            XCTAssertEqual(repository.load().status, .restored)
            XCTAssertEqual(repository.load().configuration, .defaultValue)
        }
    }
}
