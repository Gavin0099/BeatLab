import Combine
import BeatLabCore

@MainActor
final class ConfigurationStore: ObservableObject {
    @Published private(set) var configuration: MetronomeConfiguration
    @Published private(set) var notice: Notice?
    private let repository: ConfigurationRepository

    enum Notice: Equatable {
        case corruptSettings
        case unsupportedSchema
        case invalidSetting
        case saveFailed
    }

    var canEdit: Bool { notice != .unsupportedSchema }

    init(repository: ConfigurationRepository) {
        self.repository = repository
        let result = repository.load()
        configuration = result.configuration
        switch result.status {
        case .new, .restored: notice = nil
        case .corrupt: notice = .corruptSettings
        case .unsupportedVersion: notice = .unsupportedSchema
        }
    }

    func setTempo(_ bpm: Int) {
        edit { $0.setTempo(try Tempo(bpm: bpm)) }
    }

    func setTimeSignature(_ signature: TimeSignature) {
        edit { $0.setTimeSignature(signature) }
    }

    func setSubdivision(_ subdivision: Subdivision) {
        edit { try $0.setSubdivision(subdivision) }
    }

    func setAccentEnabled(_ enabled: Bool) {
        edit { $0.setAccentEnabled(enabled) }
    }

    func resetSettings() {
        repository.reset()
        edit { $0 = .defaultValue }
    }

    private func edit(_ change: (inout MetronomeConfiguration) throws -> Void) {
        var updated = configuration
        do {
            try change(&updated)
        } catch {
            // Preserve a future-schema lock even after an invalid edit attempt.
            if notice != .unsupportedSchema { notice = .invalidSetting }
            return
        }
        do {
            try repository.save(updated)
            configuration = updated
            notice = nil
        } catch ConfigurationRepository.PersistenceError.unsupportedVersion {
            notice = .unsupportedSchema
        } catch {
            notice = .saveFailed
        }
    }
}
