import Foundation
import XCTest
@testable import BeatLabCore

final class DomainTests: XCTestCase {
    func testTempoAcceptsInclusiveBoundaries() throws {
        XCTAssertEqual(try Tempo(bpm: 30).bpm, 30)
        XCTAssertEqual(try Tempo(bpm: 240).bpm, 240)
    }

    func testTempoRejectsValuesOutsideBoundaries() {
        for bpm in [Int.min, -1, 0, 29, 241, Int.max] {
            XCTAssertThrowsError(try Tempo(bpm: bpm)) {
                XCTAssertEqual($0 as? Tempo.ValidationError, .outOfRange(bpm))
            }
        }
    }

    func testTempoDecodeCannotBypassRangeValidation() {
        for json in ["29", "241", "120.5", "\"120\"", "null"] {
            XCTAssertThrowsError(try JSONDecoder().decode(Tempo.self, from: Data(json.utf8)))
        }
    }

    func testDefaultConfigurationMatchesFoundationContract() {
        let config = MetronomeConfiguration.defaultValue
        XCTAssertEqual(config.tempo.bpm, 80)
        XCTAssertEqual(config.timeSignature, .fourFour)
        XCTAssertEqual(config.subdivision, .quarter)
        XCTAssertTrue(config.accentEnabled)
    }

    func testCompoundMeterHasTwoDottedQuarterBeats() {
        XCTAssertEqual(TimeSignature.sixEight.beatsPerBar, 2)
        XCTAssertEqual(Subdivision.supported(for: .sixEight), [.compoundEighth])
        XCTAssertEqual(Subdivision.defaultValue(for: .sixEight), .compoundEighth)
    }

    func testSimpleMetersAllowFourDefinedSubdivisions() {
        XCTAssertEqual(TimeSignature.twoFour.beatsPerBar, 2)
        XCTAssertEqual(TimeSignature.threeFour.beatsPerBar, 3)
        XCTAssertEqual(TimeSignature.fourFour.beatsPerBar, 4)
        for signature in [TimeSignature.twoFour, .threeFour, .fourFour] {
            XCTAssertEqual(Subdivision.supported(for: signature), [.quarter, .eighth, .sixteenth, .triplet])
        }
    }

    func testInitializerRejectsIncompatibleSubdivision() throws {
        XCTAssertThrowsError(try MetronomeConfiguration(
            tempo: Tempo(bpm: 120), timeSignature: .sixEight,
            subdivision: .quarter, accentEnabled: true
        )) {
            XCTAssertEqual($0 as? MetronomeConfiguration.ValidationError,
                           .incompatibleSubdivision(.quarter, .sixEight))
        }
    }

    func testSignatureChangeNormalizesSubdivisionAtomically() throws {
        var config = MetronomeConfiguration.defaultValue
        try config.setSubdivision(.sixteenth)
        config.setTimeSignature(.sixEight)
        XCTAssertEqual(config.timeSignature, .sixEight)
        XCTAssertEqual(config.subdivision, .compoundEighth)
        XCTAssertEqual(config.tempo.bpm, 80)
        XCTAssertTrue(config.accentEnabled)
        config.setTimeSignature(.threeFour)
        XCTAssertEqual(config.subdivision, .quarter)
    }

    func testCompatibleSignatureChangePreservesSubdivision() throws {
        var config = MetronomeConfiguration.defaultValue
        try config.setSubdivision(.triplet)
        config.setTimeSignature(.twoFour)
        XCTAssertEqual(config.subdivision, .triplet)
    }

    func testInvalidSubdivisionEditDoesNotMutateConfiguration() {
        var config = MetronomeConfiguration.defaultValue
        XCTAssertThrowsError(try config.setSubdivision(.compoundEighth))
        XCTAssertEqual(config, .defaultValue)
    }

    func testDecodeRejectsIncompatibleOrInvalidConfiguration() {
        let fixtures = [
            #"{"tempo":120,"timeSignature":"6/8","subdivision":"quarter","accentEnabled":true}"#,
            #"{"tempo":241,"timeSignature":"4/4","subdivision":"quarter","accentEnabled":true}"#,
            #"{"tempo":80,"timeSignature":"5/4","subdivision":"quarter","accentEnabled":true}"#,
            #"{"tempo":80,"timeSignature":"4/4","subdivision":"unknown","accentEnabled":true}"#,
            #"{"tempo":80,"timeSignature":"4/4","subdivision":"quarter"}"#
        ]
        for fixture in fixtures {
            XCTAssertThrowsError(try JSONDecoder().decode(
                MetronomeConfiguration.self, from: Data(fixture.utf8)
            ))
        }
    }
}
