import XCTest
@testable import Zenith

class TaskViewModelTests: XCTestCase {
    var viewModel: TaskViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = TaskViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testLoadTasksForTodayIncludesCorrectParameters() async throws {
        // Create a URLSession mock that captures the URL and headers
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        
        // Set up the mock response
        let mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:3001/tasks")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        let mockTasks: [TodoTask] = []
        let mockData = try JSONEncoder().encode(mockTasks)
        
        // Set up expectations for the URL parameters and headers
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return (mockResponse, mockData)
        }
        
        // Call the method
        try await viewModel.loadTasks(forToday: true)
        
        // Verify the request was captured
        guard let request = capturedRequest else {
            XCTFail("No request was captured")
            return
        }
        
        // Verify headers
        XCTAssertEqual(request.value(forHTTPHeaderField: "accept"), "application/json", "Accept header should be application/json")
        
        // Verify URL parameters
        guard let url = request.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems
        else {
            XCTFail("URL is not properly formatted")
            return
        }
        
        // Check for required parameters
        XCTAssertTrue(queryItems.contains(where: { $0.name == "includeArchived" && $0.value == "false" }))
        XCTAssertTrue(queryItems.contains(where: { $0.name == "status" && $0.value == "pending" }))
        
        // Check for dueDate parameter
        let dueDateItem = queryItems.first(where: { $0.name == "dueDate" })
        XCTAssertNotNil(dueDateItem, "dueDate parameter should be present")
        
        // Verify dueDate format is YYYY-MM-DD
        if let dueDateString = dueDateItem?.value {
            // Check format
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            guard let dueDate = dateFormatter.date(from: dueDateString) else {
                XCTFail("Date string '\(dueDateString)' is not in YYYY-MM-DD format")
                return
            }
            
            let calendar = Calendar.current
            XCTAssertTrue(calendar.isDateInToday(dueDate), "Due date should be today")
            
            // Verify the string format directly with regex
            let dateRegex = try NSRegularExpression(pattern: "^\\d{4}-\\d{2}-\\d{2}$")
            let range = NSRange(dueDateString.startIndex..., in: dueDateString)
            XCTAssertTrue(dateRegex.firstMatch(in: dueDateString, range: range) != nil, "Date string should match YYYY-MM-DD format")
        }
    }
}

// Mock URLProtocol for testing network requests
class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            XCTFail("Handler is unavailable.")
            return
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}
} 