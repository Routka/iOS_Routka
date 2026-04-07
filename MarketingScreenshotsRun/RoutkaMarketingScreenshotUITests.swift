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
        app.launch()
        
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
        attachment.name = "\(localeIdentifier) 1 Regular track Recording"
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

