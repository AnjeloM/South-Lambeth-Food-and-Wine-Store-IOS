//
//  South_Lambeth_Food_and_Wine_Store_Inventory_sysUITestsLaunchTests.swift
//  South Lambeth Food and Wine Store Inventory sysUITests
//
//  Created by Mariyan Anjelo on 17/01/2026.
//

import XCTest

final class South_Lambeth_Food_and_Wine_Store_Inventory_sysUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
