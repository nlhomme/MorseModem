//
//  MorseModemUITests.swift
//  MorseModemUITests
//

import XCTest

private struct LocaleConfig {
    let language: String
    let locale: String
    let tabEncoder: String
    let tabDecoder: String
    let tabReference: String
    let tabHistory: String
    let btnSettings: String
    let btnPlayMorse: String
    let btnExportAudio: String
    let btnClear: String
    let btnStartRecording: String
    let btnImportAudio: String
    let navSettings: String
    let sliderToneFrequency: String
    let sliderSpeed: String
    let sliderVolume: String
    let sliderValueFrequency: String
    let sliderValueSpeed: String
    let sliderValueVolume: String
    let navHistory: String
}

final class MorseModemUITests: XCTestCase {

    var app: XCUIApplication!

    private static let supportedLocales: [LocaleConfig] = [
        LocaleConfig(
            language: "en", locale: "en_US",
            tabEncoder: "Encoder", tabDecoder: "Decoder", tabReference: "Reference", tabHistory: "History",
            btnSettings: "Settings", btnPlayMorse: "Play morse code",
            btnExportAudio: "Export audio file", btnClear: "Clear",
            btnStartRecording: "Start recording", btnImportAudio: "Import audio file",
            navSettings: "Settings",
            sliderToneFrequency: "Tone Frequency", sliderSpeed: "Speed", sliderVolume: "Volume",
            sliderValueFrequency: "700 hertz", sliderValueSpeed: "12 words per minute", sliderValueVolume: "80 percent",
            navHistory: "History"
        ),
        LocaleConfig(
            language: "fr", locale: "fr_FR",
            tabEncoder: "Encodeur", tabDecoder: "Décodeur", tabReference: "Référence", tabHistory: "Historique",
            btnSettings: "Réglages", btnPlayMorse: "Jouer le code Morse",
            btnExportAudio: "Exporter le fichier audio", btnClear: "Effacer",
            btnStartRecording: "Démarrer l'enregistrement", btnImportAudio: "Importer un fichier audio",
            navSettings: "Réglages",
            sliderToneFrequency: "Fréquence du son", sliderSpeed: "Vitesse", sliderVolume: "Volume",
            sliderValueFrequency: "700 hertz", sliderValueSpeed: "12 mots par minute", sliderValueVolume: "80 pour cent",
            navHistory: "Historique"
        )
    ]

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func launch(with config: LocaleConfig) {
        app.launchArguments = ["-AppleLanguages", "(\(config.language))", "-AppleLocale", config.locale]
        app.launch()
    }

    // iOS 18 floating tab bar nests two Button elements per item with the same label.
    // Using firstMatch avoids the "multiple matching elements" error from .tap().
    private func tapTab(_ label: String) {
        app.buttons.matching(NSPredicate(format: "label == %@", label)).firstMatch.tap()
    }

    // MARK: - Tab Bar

    @MainActor
    func testTabBarAccessibilityLabels() {
        // iOS 18 uses a floating tab bar (_UIFloatingTabBarItemCell), not UITabBar,
        // so scope to the app level rather than app.tabBars.
        for config in Self.supportedLocales {
            launch(with: config)
            let tag = "[\(config.language)]"
            XCTAssertTrue(app.buttons[config.tabEncoder].exists, "\(tag) '\(config.tabEncoder)' tab missing")
            XCTAssertTrue(app.buttons[config.tabDecoder].exists, "\(tag) '\(config.tabDecoder)' tab missing")
            XCTAssertTrue(app.buttons[config.tabReference].exists, "\(tag) '\(config.tabReference)' tab missing")
            XCTAssertTrue(app.buttons[config.tabHistory].exists, "\(tag) '\(config.tabHistory)' tab missing")
            app.terminate()
        }
    }

    // MARK: - Encoder Tab

    @MainActor
    func testEncoderInteractiveElementsAreAccessible() {
        for config in Self.supportedLocales {
            launch(with: config)
            let tag = "[\(config.language)]"
            XCTAssertTrue(app.buttons[config.btnSettings].exists, "\(tag) Settings button missing")
            XCTAssertTrue(app.buttons[config.btnPlayMorse].exists, "\(tag) Play button missing")
            XCTAssertTrue(app.buttons[config.btnExportAudio].exists, "\(tag) Export button missing")
            XCTAssertTrue(app.buttons[config.btnClear].exists, "\(tag) Clear button missing")
            app.terminate()
        }
    }

    @MainActor
    func testEncoderMorseCodeHiddenFromAccessibilityTree() {
        // Morse encoding is language-independent; verify once using the first supported locale.
        launch(with: Self.supportedLocales[0])
        let config = Self.supportedLocales[0]
        // Wait for splash screen to clear (1.5 s display + 0.3 s fade) before querying
        XCTAssertTrue(app.buttons[config.btnSettings].waitForExistence(timeout: 5))
        // TextField(axis:.vertical) renders as textView; fall back to textField on future iOS
        let textInput: XCUIElement
        if app.textViews.firstMatch.exists {
            textInput = app.textViews.firstMatch
        } else {
            textInput = app.textFields.firstMatch
        }
        XCTAssertTrue(textInput.exists, "Text input field not found in encoder")
        textInput.tap()
        textInput.typeText("SOS")
        // "SOS" encodes to "... --- ..." — must not be reachable via the accessibility tree
        XCTAssertFalse(app.staticTexts["... --- ..."].exists)
    }

    // MARK: - Decoder Tab

    @MainActor
    func testDecoderInteractiveElementsAreAccessible() {
        for config in Self.supportedLocales {
            launch(with: config)
            let tag = "[\(config.language)]"
            // Wait for splash to clear before tapping tab (avoids silent tap failure on iPad)
            XCTAssertTrue(app.buttons[config.btnSettings].waitForExistence(timeout: 5))
            tapTab(config.tabDecoder)
            XCTAssertTrue(app.buttons[config.btnStartRecording].waitForExistence(timeout: 5), "\(tag) Start recording button missing")
            XCTAssertTrue(app.buttons[config.btnImportAudio].exists, "\(tag) Import audio button missing")
            app.terminate()
        }
    }

    // MARK: - Settings Sheet

    @MainActor
    func testSettingsSlidersAreAccessible() {
        for config in Self.supportedLocales {
            launch(with: config)
            let tag = "[\(config.language)]"
            app.buttons[config.btnSettings].tap()
            XCTAssertTrue(app.navigationBars[config.navSettings].waitForExistence(timeout: 2), "\(tag) Settings nav bar missing")
            XCTAssertTrue(app.sliders[config.sliderToneFrequency].exists, "\(tag) Tone Frequency slider missing")
            XCTAssertTrue(app.sliders[config.sliderSpeed].exists, "\(tag) Speed slider missing")
            XCTAssertTrue(app.sliders[config.sliderVolume].exists, "\(tag) Volume slider missing")
            app.terminate()
        }
    }

    @MainActor
    func testSettingsSliderDefaultValues() {
        for config in Self.supportedLocales {
            launch(with: config)
            let tag = "[\(config.language)]"
            app.buttons[config.btnSettings].tap()
            XCTAssertTrue(app.navigationBars[config.navSettings].waitForExistence(timeout: 2), "\(tag) Settings nav bar missing")
            XCTAssertEqual(app.sliders[config.sliderToneFrequency].value as? String, config.sliderValueFrequency, "\(tag) Frequency default wrong")
            XCTAssertEqual(app.sliders[config.sliderSpeed].value as? String, config.sliderValueSpeed, "\(tag) Speed default wrong")
            XCTAssertEqual(app.sliders[config.sliderVolume].value as? String, config.sliderValueVolume, "\(tag) Volume default wrong")
            app.terminate()
        }
    }

    // MARK: - Encoder Interaction

    @MainActor
    func testEncoderTypingEnablesButtons() {
        for config in Self.supportedLocales {
            launch(with: config)
            let tag = "[\(config.language)]"
            XCTAssertTrue(app.buttons[config.btnSettings].waitForExistence(timeout: 5))
            let textInput: XCUIElement = app.textViews.firstMatch.exists
                ? app.textViews.firstMatch
                : app.textFields.firstMatch
            XCTAssertTrue(textInput.exists, "\(tag) Text input not found")
            textInput.tap()
            textInput.typeText("A")
            XCTAssertTrue(app.buttons[config.btnClear].isEnabled, "\(tag) Clear should be enabled after typing")
            app.terminate()
        }
    }

    // MARK: - History Tab

    @MainActor
    func testHistoryTabNavigationTitle() {
        for config in Self.supportedLocales {
            launch(with: config)
            let tag = "[\(config.language)]"
            // Wait for splash to clear before navigating
            XCTAssertTrue(app.buttons[config.btnSettings].waitForExistence(timeout: 5))
            tapTab(config.tabHistory)
            // On iPad the sidebar TabView layout doesn't produce a navigationBars entry;
            // the History search field is a more universal anchor.
            XCTAssertTrue(
                app.searchFields.firstMatch.waitForExistence(timeout: 5),
                "\(tag) History search field not found after navigation"
            )
            app.terminate()
        }
    }

    // MARK: - Reference Tab

    @MainActor
    func testReferenceSearchFieldIsAccessible() {
        for config in Self.supportedLocales {
            launch(with: config)
            let tag = "[\(config.language)]"
            // Wait for splash to clear before tapping tab (avoids silent tap failure on iPad)
            XCTAssertTrue(app.buttons[config.btnSettings].waitForExistence(timeout: 5))
            tapTab(config.tabReference)
            let searchField = app.searchFields.firstMatch
            XCTAssertTrue(searchField.waitForExistence(timeout: 3), "\(tag) Reference search field not found")
            searchField.tap()
            searchField.typeText("A")
            XCTAssertEqual(searchField.value as? String, "A", "\(tag) Search field should contain typed text")
            app.terminate()
        }
    }

    // MARK: - Performance

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
