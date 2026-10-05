import Combine
import BeatLabCore

@MainActor
final class ConfigurationStore: ObservableObject {
    @Published private(set) var configuration: MetronomeConfiguration
    @Published private(set) var notice: Notice?
    @Published private(set) var undoTempos: [Int] = []
    @Published private(set) var redoTempos: [Int] = []
    private var gestureOriginalTempo: Int?
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
        let before = configuration.tempo.bpm
        guard before != bpm, edit({ $0.setTempo(try Tempo(bpm: bpm)) }) else { return }
        if gestureOriginalTempo == nil { rememberTempo(before) }
    }

    func beginTempoGesture() { gestureOriginalTempo = configuration.tempo.bpm }
    func endTempoGesture() {
        if let original = gestureOriginalTempo, original != configuration.tempo.bpm { rememberTempo(original) }
        gestureOriginalTempo = nil
    }
    func undoTempo() {
        guard let previous = undoTempos.last else { return }
        let current = configuration.tempo.bpm
        guard edit({ $0.setTempo(try Tempo(bpm: previous)) }) else { return }
        undoTempos.removeLast(); redoTempos.append(current)
    }
    func redoTempo() {
        guard let next = redoTempos.last else { return }
        let current = configuration.tempo.bpm
        guard edit({ $0.setTempo(try Tempo(bpm: next)) }) else { return }
        redoTempos.removeLast(); undoTempos.append(current)
    }
    private func rememberTempo(_ bpm: Int) {
        undoTempos.append(bpm)
        if undoTempos.count > 50 { undoTempos.removeFirst() }
        redoTempos.removeAll()
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

    func cycleBeat(at index: Int) { edit { try $0.cycleBeat(at: index) } }
    func setClickTimbre(_ value: ClickTimbre) { edit { $0.setClickTimbre(value) } }
    func setScreenPulseEnabled(_ enabled: Bool) { edit { $0.setScreenPulseEnabled(enabled) } }
    func setHapticsEnabled(_ enabled: Bool) { edit { $0.setHapticsEnabled(enabled) } }

    func resetSettings() {
        repository.reset()
        edit { $0 = .defaultValue }
        undoTempos.removeAll(); redoTempos.removeAll(); gestureOriginalTempo = nil
    }

    @discardableResult
    private func edit(_ change: (inout MetronomeConfiguration) throws -> Void) -> Bool {
        var updated = configuration
        do {
            try change(&updated)
        } catch {
            // Preserve a future-schema lock even after an invalid edit attempt.
            if notice != .unsupportedSchema { notice = .invalidSetting }
            return false
        }
        do {
            try repository.save(updated)
            configuration = updated
            notice = nil
            return true
        } catch ConfigurationRepository.PersistenceError.unsupportedVersion {
            notice = .unsupportedSchema
        } catch {
            notice = .saveFailed
        }
        return false
    }
}
