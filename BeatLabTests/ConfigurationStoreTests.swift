import Foundation
import XCTest
import BeatLabCore
@testable import BeatLab

final class ConfigurationStoreTests: XCTestCase {
    @MainActor
    func testTempoUndoRedoGroupsSliderAndPreservesOtherSettings() async throws {
        try withRepository { repository, _ in
            let store = ConfigurationStore(repository: repository)
            store.setTempo(120)
            store.beginTempoGesture()
            store.setTempo(121); store.setTempo(137); store.setTempo(150)
            store.endTempoGesture()
            store.setClickTimbre(.woodblock)
            store.cycleBeat(at: 1)
            store.undoTempo()
            XCTAssertEqual(store.configuration.tempo.bpm, 120)
            XCTAssertEqual(store.configuration.clickTimbre, .woodblock)
            XCTAssertEqual(store.configuration.beatEmphases[1], .muted)
            store.undoTempo()
            XCTAssertEqual(store.configuration.tempo.bpm, 80)
            store.redoTempo()
            XCTAssertEqual(store.configuration.tempo.bpm, 120)
            store.setTempo(100)
            XCTAssertTrue(store.redoTempos.isEmpty)
            let history = store.undoTempos
            store.setTempo(241)
            XCTAssertEqual(store.undoTempos, history)
            XCTAssertEqual(repository.load().configuration.tempo.bpm, 100)
        }
    }

    @MainActor
    func testFutureSchemaBlocksUndoAndNewSettingsWithoutLosingHistory() async throws {
        try withRepository { repository, defaults in
            let store = ConfigurationStore(repository: repository)
            store.setTempo(120)
            let future = Data(#"{"schemaVersion":99}"#.utf8)
            defaults.set(future, forKey: ConfigurationRepository.storageKey)
            store.undoTempo()
            store.setClickTimbre(.mechanical)
            store.cycleBeat(at: 0)
            store.setHapticsEnabled(true)
            XCTAssertEqual(store.configuration.tempo.bpm, 120)
            XCTAssertEqual(store.undoTempos, [80])
            XCTAssertTrue(store.redoTempos.isEmpty)
            XCTAssertEqual(store.configuration.beatEmphases[0], .accent)
            XCTAssertEqual(defaults.data(forKey: ConfigurationRepository.storageKey), future)
        }
    }

    @MainActor
    private func withRepository(_ body: (ConfigurationRepository, UserDefaults) throws -> Void) throws {
        let suite = "BeatLabStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        try body(ConfigurationRepository(defaults: defaults), defaults)
    }

    @MainActor
    func testEditsShareOneConfigurationAndSurviveNewStore() async throws {
        try withRepository { repository, _ in
            let store = ConfigurationStore(repository: repository)
            store.setTempo(137)
            store.setTimeSignature(.threeFour)
            store.setSubdivision(.eighth)
            store.setAccentEnabled(false)
            let restored = ConfigurationStore(repository: repository)
            XCTAssertEqual(restored.configuration, store.configuration)
            XCTAssertEqual(restored.configuration.tempo.bpm, 137)
            XCTAssertEqual(restored.configuration.timeSignature, .threeFour)
            XCTAssertEqual(restored.configuration.subdivision, .eighth)
            XCTAssertFalse(restored.configuration.accentEnabled)
            XCTAssertNil(restored.notice)
        }
    }

    @MainActor
    func testInvalidTempoLeavesConfigurationAndPersistenceUnchanged() async throws {
        try withRepository { repository, defaults in
            let store = ConfigurationStore(repository: repository)
            store.setTempo(241)
            XCTAssertEqual(store.configuration, .defaultValue)
            XCTAssertEqual(store.notice, .invalidSetting)
            XCTAssertNil(defaults.object(forKey: ConfigurationRepository.storageKey))
            XCTAssertEqual(repository.load().status, .new)
        }
    }

    @MainActor
    func testMeterChangePersistsNormalizedSubdivisionTogether() async throws {
        try withRepository { repository, _ in
            let store = ConfigurationStore(repository: repository)
            store.setSubdivision(.sixteenth)
            store.setTimeSignature(.sixEight)
            XCTAssertEqual(store.configuration.subdivision, .compoundEighth)
            XCTAssertEqual(repository.load().configuration, store.configuration)
            store.setSubdivision(.quarter)
            XCTAssertEqual(store.configuration.subdivision, .compoundEighth)
            XCTAssertEqual(store.notice, .invalidSetting)
            XCTAssertEqual(repository.load().configuration, store.configuration)
        }
    }

    @MainActor
    func testCorruptSettingsProduceVisibleRecoverableNotice() async throws {
        try withRepository { repository, defaults in
            defaults.set(Data("corrupt".utf8), forKey: ConfigurationRepository.storageKey)
            let store = ConfigurationStore(repository: repository)
            XCTAssertEqual(store.configuration, .defaultValue)
            XCTAssertEqual(store.notice, .corruptSettings)
            store.setTempo(60)
            XCTAssertNil(store.notice)
            XCTAssertEqual(repository.load().configuration.tempo.bpm, 60)
        }
    }

    @MainActor
    func testUnsupportedSettingsRemainUntouchedUntilExplicitReset() async throws {
        try withRepository { repository, defaults in
            let future = Data(#"{"schemaVersion":99,"future":"preserve"}"#.utf8)
            defaults.set(future, forKey: ConfigurationRepository.storageKey)
            let store = ConfigurationStore(repository: repository)
            XCTAssertFalse(store.canEdit)
            store.setTempo(100)
            XCTAssertEqual(store.configuration, .defaultValue)
            XCTAssertEqual(store.notice, .unsupportedSchema)
            XCTAssertFalse(store.canEdit)
            store.setTempo(241)
            XCTAssertFalse(store.canEdit)
            XCTAssertEqual(defaults.data(forKey: ConfigurationRepository.storageKey), future)
            store.resetSettings()
            XCTAssertTrue(store.canEdit)
            XCTAssertNil(store.notice)
            XCTAssertEqual(repository.load().status, .restored)
            XCTAssertEqual(repository.load().configuration, .defaultValue)
        }
    }
}
