import XCTest
@testable import Zenith

@MainActor
final class ProjectViewModelTests: XCTestCase {
    var viewModel: ProjectViewModel!
    
    override func setUp() async throws {
        viewModel = ProjectViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
    }
    
    func testInboxProjectLoading() async throws {
        // Load projects
        try await viewModel.loadProjects()
        
        // Verify that we have at least one project (the Inbox)
        XCTAssertFalse(viewModel.projects.isEmpty, "Projects list should not be empty")
        
        // Find the Inbox project
        let inboxProject = viewModel.projects.first { $0.isSystem }
        
        // Verify that the Inbox project exists
        XCTAssertNotNil(inboxProject, "Inbox project should be present in the projects list")
        
        // Verify Inbox project properties
        if let inbox = inboxProject {
            XCTAssertTrue(inbox.isSystem, "Inbox project should have isSystem = true")
            XCTAssertEqual(inbox.name, "Entrada", "Inbox project should be named 'Entrada'")
            XCTAssertFalse(inbox.isArchived, "Inbox project should not be archived")
        }
    }
} 