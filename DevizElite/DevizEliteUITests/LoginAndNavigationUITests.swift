import XCTest

final class LoginAndNavigationUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testLoginScreenAndSidebar() throws {
        // Login screen shows fields and buttons
        XCTAssertTrue(app.textFields["Email"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.secureTextFields["Password"].exists)
        XCTAssertTrue(app.buttons["Sign In"].exists)

        // Navigate after mock sign in by registering
        app.textFields["Email"].click()
        app.typeText("ui@example.com")
        app.secureTextFields["Password"].click()
        app.typeText("pass123")
        app.buttons["Register"].click()

        // Sidebar should appear
        XCTAssertTrue(app.buttons["Clients"].waitForExistence(timeout: 5))
        app.buttons["Clients"].click()
    }
}


