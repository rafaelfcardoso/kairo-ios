import XCTest

@MainActor
final class CreateTaskViewUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUp() async throws {
        continueAfterFailure = false
        app.launch()
        
        // Ensure we're on the Today tab
        let todayTab = app.tabBars.buttons["Hoje"]
        XCTAssertTrue(todayTab.waitForExistence(timeout: 5), "Today tab should exist")
        todayTab.tap()
        
        // Wait for the add button and tap it
        let addButton = app.buttons["add-task-button"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Add button should exist")
        addButton.tap()
        
        // Verify we're in the create task view
        let taskNameField = app.textFields["Nova tarefa"]
        XCTAssertTrue(taskNameField.waitForExistence(timeout: 5), "Task creation view should be visible")
        
        // Wait for projects to load
        try await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds for projects to load
    }
    
    func testProjectSelectionMenuExists() async throws {
        // Verify the project menu button exists and shows "Caixa de Entrada" by default
        let projectButton = app.buttons["project-selector"]
        XCTAssertTrue(projectButton.waitForExistence(timeout: 5), "Project selector button should exist")
        
        let buttonText = projectButton.label
        XCTAssertEqual(buttonText, "Caixa de Entrada", "Project selector should show 'Caixa de Entrada' by default")
    }
    
    func testProjectMenuShowsInboxFirst() async throws {
        // Open the project menu
        let projectButton = app.buttons["project-selector"]
        XCTAssertTrue(projectButton.waitForExistence(timeout: 5), "Project selector button should exist")
        projectButton.tap()
        
        // Wait for menu items to load and verify inbox is first
        let inboxOption = app.buttons["inbox-option"]
        XCTAssertTrue(inboxOption.waitForExistence(timeout: 5), "Inbox option should exist")
        
        let inboxText = inboxOption.staticTexts["Caixa de Entrada"]
        XCTAssertTrue(inboxText.exists, "First item should be 'Caixa de Entrada'")
    }
    
    func testProjectSelectionPersists() async throws {
        // Open project menu
        let projectButton = app.buttons["project-selector"]
        XCTAssertTrue(projectButton.waitForExistence(timeout: 5), "Project selector button should exist")
        projectButton.tap()
        
        // Select inbox project
        let inboxOption = app.buttons["inbox-option"]
        XCTAssertTrue(inboxOption.waitForExistence(timeout: 5), "Inbox option should exist")
        inboxOption.tap()
        
        // Wait for selection to update
        try await Task.sleep(nanoseconds: 500_000_000) // Wait 0.5 seconds
        
        // Verify selection persisted
        let buttonText = projectButton.label
        XCTAssertEqual(buttonText, "Caixa de Entrada", "Selected project name should be displayed")
    }
    
    func testCreateTaskWithSelectedProject() async throws {
        // Enter task details
        let taskNameField = app.textFields["Nova tarefa"]
        XCTAssertTrue(taskNameField.waitForExistence(timeout: 5), "Task name field should exist")
        taskNameField.tap()
        taskNameField.typeText("Test Task")
        
        // Select a project
        let projectButton = app.buttons["project-selector"]
        XCTAssertTrue(projectButton.waitForExistence(timeout: 5), "Project selector button should exist")
        projectButton.tap()
        
        // Select inbox project
        let inboxOption = app.buttons["inbox-option"]
        XCTAssertTrue(inboxOption.waitForExistence(timeout: 5), "Inbox option should exist")
        inboxOption.tap()
        
        // Submit task and wait for dismissal
        taskNameField.typeText("\n")
        try await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds for save and dismiss
        
        // Verify task was created
        XCTAssertFalse(taskNameField.exists, "Should dismiss create task view after submission")
    }
} 
