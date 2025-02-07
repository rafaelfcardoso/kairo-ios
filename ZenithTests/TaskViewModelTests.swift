import XCTest
@testable import Zenith

final class TaskViewModelTests: XCTestCase {
    var viewModel: TaskViewModel!
    var mockURLSession: URLSession!
    
    override func setUp() async throws {
        // Create URL session configuration that allows us to mock network requests
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockURLSession = URLSession(configuration: configuration)
        
        // Initialize view model on the main actor
        await MainActor.run {
            viewModel = TaskViewModel()
        }
    }
    
    override func tearDown() async throws {
        await MainActor.run {
            viewModel = nil
        }
        mockURLSession = nil
        MockURLProtocol.mockData = nil
        MockURLProtocol.mockResponse = nil
        MockURLProtocol.mockError = nil
    }
    
    func testLoadTasksForTodayIncludesCorrectParameters() async throws {
        // Prepare mock response
        let mockTasks = [
            ["id": "1", "title": "Task 1", "dueDate": "2024-02-03T23:59:59Z"],
            ["id": "2", "title": "Task 2", "dueDate": "2024-02-03T23:59:59Z"]
        ]
        
        MockURLProtocol.mockData = try JSONSerialization.data(withJSONObject: mockTasks)
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:3001/tasks")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )
        
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return (MockURLProtocol.mockResponse!, MockURLProtocol.mockData!)
        }
        
        // Load tasks
        try await viewModel.loadTasks(forToday: true)
        
        // Verify request
        XCTAssertNotNil(capturedRequest, "Request should have been captured")
        XCTAssertEqual(capturedRequest?.url?.host, "localhost", "Host should be localhost")
        XCTAssertEqual(capturedRequest?.url?.port, 3001, "Port should be 3001")
        XCTAssertEqual(capturedRequest?.url?.path, "/tasks", "Path should be /tasks")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "accept"), "application/json", "Accept header should be application/json")
        
        // Verify tasks were loaded
        await MainActor.run {
            XCTAssertEqual(viewModel.tasks.count, 2, "Should have loaded 2 tasks")
        }
    }
}

// Mock URL Protocol for testing network requests
class MockURLProtocol: URLProtocol {
    static var mockData: Data?
    static var mockResponse: URLResponse?
    static var mockError: Error?
    static var requestHandler: ((URLRequest) throws -> (URLResponse, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let handler = MockURLProtocol.requestHandler {
            do {
                let (response, data) = try handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        } else if let error = MockURLProtocol.mockError {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            guard let response = MockURLProtocol.mockResponse,
                  let data = MockURLProtocol.mockData else {
                return
            }
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        }
    }
    
    override func stopLoading() {}
} 