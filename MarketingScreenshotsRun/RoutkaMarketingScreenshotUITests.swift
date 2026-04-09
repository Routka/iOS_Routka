//
//  RoutkaMarketingScreenshotUITests.swift
//  RoutkaUITests
//
//  Created by vladukha on 07.04.2026.
//
import XCTest
import CoreLocation
import Foundation


final class RoutkaMarketingScreenshotUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    @MainActor
    func test_generateRegularTrackRecordingScreen() async throws {
        var track = try self.loadTrack(named: "FreewayDrive").points
        XCTAssertFalse(track.isEmpty)

        let app = XCUIApplication()
        
        app.launchArguments.append("UITestingDarkModeEnabled")
        app.launch()
        await self.dismissDisclaimerIfPresent(onApp: app)
        app.allowLocation()
        
        let startingPoint = track.removeFirst()
        XCUIDevice.goTo(startingPoint)

        app.buttons["startRecordingButton"].tap()
        
        var previousPoint = startingPoint
        for point in track {
            let delay = max(0, point.date.timeIntervalSince(previousPoint.date))
            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }

            XCUIDevice.goTo(point)
            previousPoint = point
        }

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "\(localeIdentifier).1 Regular track Recording"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func test_generateMeasurementRecordedScreen() async throws {
        var track = try self.loadTrack(named: "FreewayDrive").points
        XCTAssertFalse(track.isEmpty)

        let app = XCUIApplication()
        app.launchArguments.append("UITestingDarkModeEnabled")
        app.launch()
        await self.dismissDisclaimerIfPresent(onApp: app)
        app.allowLocation()
        
        let startingPoint = track.removeFirst()
        XCUIDevice.goTo(startingPoint)
        
        let selectorButton = app.buttons["measuredTracksSelector"]
        XCTAssertTrue(selectorButton.waitForExistence(timeout: 5))
        selectorButton.tap()

        XCTAssertTrue(app.staticTexts["measurementPresetsTitle"].waitForExistence(timeout: 5))

        app.buttons["PresetButton1/2 mile"].tap()
        
        let startingLocation = CLLocation(
            latitude: startingPoint.position.latitude,
            longitude: startingPoint.position.longitude
        )
        let halfMileInMeters = Measurement(value: 0.5, unit: UnitLength.miles)
            .converted(to: .meters)
            .value
        var previousPoint = startingPoint
        for point in track {
            let delay = max(0, point.date.timeIntervalSince(previousPoint.date))
            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }

            XCUIDevice.goTo(point)
            previousPoint = point

            let currentLocation = CLLocation(
                latitude: point.position.latitude,
                longitude: point.position.longitude
            )
            if startingLocation.distance(from: currentLocation) > halfMileInMeters {
                break
            }
        }
        sleep(4)

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "\(localeIdentifier).3 Measurement done"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func test_generatePresetSelector() async throws {
        let app = XCUIApplication()
                app.launchArguments.append("UITestingDarkModeEnabled")
        app.launch()
        await self.dismissDisclaimerIfPresent(onApp: app)
        app.allowLocation()
        
        let dismissDisclaimer = app.buttons["DismissDisclaimerButton"]
        if dismissDisclaimer.waitForExistence(timeout: 2) {
            
            let predicate = NSPredicate(format: "isEnabled == true")
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: dismissDisclaimer)
            await fulfillment(of: [expectation], timeout: 8)
            dismissDisclaimer.tap()
        }

        let selectorButton = app.buttons["measuredTracksSelector"]
        XCTAssertTrue(selectorButton.waitForExistence(timeout: 5))
        selectorButton.tap()

        XCTAssertTrue(app.staticTexts["measurementPresetsTitle"].waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "\(localeIdentifier).2 Preset selector"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func test_journal() async throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITestingDarkModeEnabled")
        app.launch()
        await self.dismissDisclaimerIfPresent(onApp: app)

        let tracksTab = app.tabBars.firstMatch.buttons.allElementsBoundByIndex[1]
        XCTAssertTrue(tracksTab.waitForExistence(timeout: 5))
        sleep(2)
        tracksTab.tap()

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "\(localeIdentifier).4 Review Journal"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func test_trackStats() async throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITestingDarkModeEnabled")
        app.launch()
        await self.dismissDisclaimerIfPresent(onApp: app)

        let tracksTab = app.tabBars.firstMatch.buttons.allElementsBoundByIndex[1]
        XCTAssertTrue(tracksTab.waitForExistence(timeout: 5))
        sleep(2)
        tracksTab.tap()

        let firstHistoryTrack = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "historyTrackButton_")
        ).firstMatch
        XCTAssertTrue(firstHistoryTrack.waitForExistence(timeout: 5))
        firstHistoryTrack.tap()

        let replayHint = app.staticTexts["replayHint"]
        XCTAssertTrue(replayHint.waitForExistence(timeout: 5))

        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        start.press(forDuration: 1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
        
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "\(localeIdentifier).5 Track stats"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func test_TrackEdit() async throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITestingDarkModeEnabled")
        app.launch()
        await self.dismissDisclaimerIfPresent(onApp: app)

        let tracksTab = app.tabBars.firstMatch.buttons.allElementsBoundByIndex[1]
        XCTAssertTrue(tracksTab.waitForExistence(timeout: 5))
        sleep(2)
        tracksTab.tap()

        let firstHistoryTrack = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "historyTrackButton_")
        ).firstMatch
        XCTAssertTrue(firstHistoryTrack.waitForExistence(timeout: 5))
        firstHistoryTrack.tap()
        
        app.swipeUp()
        app.buttons["editTrackButton"].tap()
        let playButton = app.buttons["startTag"]
        let stopButton = app.buttons["stopTag"]
        let appFrame = app.frame
        let startPlay = app.coordinate(withNormalizedOffset: CGVector(dx: playButton.frame.midX/appFrame.width,
                                                                      dy: playButton.frame.midY/appFrame.height))
        let endPlay = app.coordinate(withNormalizedOffset: CGVector(dx: (playButton.frame.midX/appFrame.width) + 0.15,
                                                                    dy: playButton.frame.midY/appFrame.height))
        startPlay.press(forDuration: 0.2, thenDragTo: endPlay, withVelocity: .slow, thenHoldForDuration: 0.1)
        
        let startEnd = app.coordinate(withNormalizedOffset: CGVector(dx: stopButton.frame.midX/appFrame.width,
                                                                      dy: stopButton.frame.midY/appFrame.height))
        let endEnd = app.coordinate(withNormalizedOffset: CGVector(dx: (stopButton.frame.midX/appFrame.width) - 0.15,
                                                                    dy: stopButton.frame.midY/appFrame.height))
        startEnd.press(forDuration: 0.2, thenDragTo: endEnd, withVelocity: .slow, thenHoldForDuration: 0.1)
        
                let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                attachment.name = "\(localeIdentifier).6 Track edit"
                attachment.lifetime = .keepAlways
                add(attachment)
    }
    
    @MainActor
    private func loadTrack(named name: String) throws -> Track {
        let bundle = Bundle(for: Self.self)
        guard let url = bundle.url(forResource: name, withExtension: "routka") else {
            XCTFail("Missing \(name).routka in UI tests bundle.")
            throw NSError(domain: "RoutkaMarketingScreenshotUITests", code: 1)
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Track.self, from: data)
    }

    private var localeIdentifier: String {
        guard let preferredLanguage = Locale.preferredLanguages.first else {
            return "en"
        }

        return Locale(identifier: preferredLanguage).language.languageCode?.identifier ?? preferredLanguage
    }

}

extension XCTestCase {
    @MainActor
    func dismissDisclaimerIfPresent(onApp app : XCUIApplication) async {
        
        let dismissDisclaimer = app.buttons["DismissDisclaimerButton"]
        if dismissDisclaimer.waitForExistence(timeout: 2) {
            
            let predicate = NSPredicate(format: "isEnabled == true")
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: dismissDisclaimer)
            await self.fulfillment(of: [expectation], timeout: 8)
            dismissDisclaimer.tap()
        }
    }
}

fileprivate extension XCUIApplication {
    func allowLocation() {
        let app = self
        let provideLocBtn = app.buttons["ProvideLocationButton"]
        if provideLocBtn.waitForExistence(timeout: 2) {
            provideLocBtn.tap()
        } else {
            return
        }
        let springboardApp = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboardApp.buttons.allElementsBoundByIndex.count > 1 {
            springboardApp.buttons.element(boundBy: 1).tap()
        }
//        springboardApp.buttons["Allow While Using App"].firstMatch.tap()
//        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
//        start.press(forDuration: 0.5)
    }
}

