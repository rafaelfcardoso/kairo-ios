import XCTest

final class AuthFlowUITests: XCTestCase {
    let validEmail = "user@example.com" // Replace with a valid test account
    let validPassword = "password123" // Replace with a valid test password

    override func setUpWithError() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["-reset-auth", "-UITestMockLogin"]
        app.launch()
    }

    func testLoginAndLoadTodayScreen() throws {
        let app = XCUIApplication()

        // Ensure LoginView is shown
        let emailField = app.textFields["EmailField"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        let passwordField = app.secureTextFields["PasswordField"]
        XCTAssertTrue(passwordField.exists)
        let signInButton = app.buttons["SignInButton"]
        XCTAssertTrue(signInButton.exists)

        // Enter credentials
        emailField.tap()
        emailField.typeText(validEmail)

        passwordField.tap()
        passwordField.typeText(validPassword)

        // Tap Sign In
        signInButton.tap()

        // Wait for Today greeting to appear
        let todayGreeting = app.staticTexts["TodayGreeting"]
        XCTAssertTrue(todayGreeting.waitForExistence(timeout: 10), "Today greeting did not appear after login")

        // Optionally, validate that some tasks are loaded (if identifiers are set)
        // let taskCell = app.cells.matching(identifier: "task-row").firstMatch
        // XCTAssertTrue(taskCell.waitForExistence(timeout: 5), "No tasks loaded on Today screen after login")
    }
}
