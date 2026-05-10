//
//  MorseModemUITests.swift
//  MorseModemUITests
//

import XCTest

final class MorseModemUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Tab Bar

    @MainActor
    func testTabBarAccessibilityLabels() {
        XCTAssertTrue(app.tabBars.buttons["Encoder"].exists)
        XCTAssertTrue(app.tabBars.buttons["Decoder"].exists)
        XCTAssertTrue(app.tabBars.buttons["Reference"].exists)
        XCTAssertTrue(app.tabBars.buttons["History"].exists)
    }

    // MARK: - Encoder Tab

    @MainActor
    func testEncoderInteractiveElementsAreAccessible() {
        XCTAssertTrue(app.buttons["Settings"].exists)
        XCTAssertTrue(app.buttons["Play morse code"].exists)
        XCTAssertTrue(app.buttons["Export audio file"].exists)
        XCTAssertTrue(app.buttons["Clear"].exists)
    }

    @MainActor
    func testEncoderMorseCodeHiddenFromAccessibilityTree() {
        // SwiftUI TextField with axis:.vertical renders as UITextView
        let textInput = app.textViews.firstMatch
        XCTAssertTrue(textInput.waitForExistence(timeout: 2))
        textInput.tap()
        textInput.typeText("SOS")
        // "SOS" encodes to "... --- ..." — must not be reachable via the accessibility tree
        XCTAssertFalse(app.staticTexts["... --- ..."].exists)
    }

    // MARK: - Decoder Tab

    @MainActor
    func testDecoderInteractiveElementsAreAccessible() {
        app.tabBars.buttons["Decoder"].tap()
        XCTAssertTrue(app.buttons["Start recording"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Import audio file"].exists)
    }

    // MARK: - Settings Sheet

    @MainActor
    func testSettingsSlidersAreAccessible() {
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.sliders["Tone Frequency"].exists)
        XCTAssertTrue(app.sliders["Speed"].exists)
        XCTAssertTrue(app.sliders["Volume"].exists)
    }

    @MainActor
    func testSettingsSliderDefaultValues() {
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.sliders["Tone Frequency"].value as? String, "700 hertz")
        XCTAssertEqual(app.sliders["Speed"].value as? String, "12 words per minute")
        XCTAssertEqual(app.sliders["Volume"].value as? String, "80 percent")
    }

    // MARK: - Performance

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
