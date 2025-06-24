import Foundation
import MCP

/// ZenithMCP provides a singleton/factory for MCP Client configured for Zenith.
final class ZenithMCP {
    static let shared = ZenithMCP()
    let client: Client
    let apiKey = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String
    private var isInitialized = false
    
    private init() {
        let url = URL(string: "https://zenith-api-development.up.railway.app/mcp")!
        let config = URLSessionConfiguration.default
        var headers: [String: String] = [
            "X-Service-Key": APIConfig.serviceKey,
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        if let token = APIConfig.authToken {
            headers["Authorization"] = "Bearer \(token)"
        }
        config.httpAdditionalHeaders = headers
        let transport = HTTPClientTransport(endpoint: url, configuration: config)
        self.client = Client(name: "Zenith", version: "1.0.0")
        Task {
            do {
                try await self.client.connect(transport: transport)
                try await self.client.initialize()
                isInitialized = true
                print("✅ MCP client initialized successfully")
            } catch {
                print("❌ MCP client initialization failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// For testing or advanced usage, create a custom instance with specific endpoint.
    static func makeCustom(endpoint: URL, name: String = "Zenith", version: String = "1.0.0") -> Client {
        // Ensure endpoint ends with /mcp
        var finalEndpoint = endpoint
        if !endpoint.absoluteString.hasSuffix("/mcp") {
            finalEndpoint = URL(string: endpoint.absoluteString + "/mcp")!
        }
        
        let config = URLSessionConfiguration.default
        var headers: [String: String] = [
            "X-Service-Key": APIConfig.serviceKey,
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        if let token = APIConfig.authToken {
            headers["Authorization"] = "Bearer \(token)"
        }
        config.httpAdditionalHeaders = headers
        let transport = HTTPClientTransport(endpoint: finalEndpoint, configuration: config)
        let client = Client(name: name, version: version)
        Task {
            do {
                try await client.connect(transport: transport)
                try await client.initialize()
                print("✅ Custom MCP client initialized successfully")
            } catch {
                print("❌ Custom MCP client initialization failed: \(error.localizedDescription)")
            }
        }
        return client
    }
}
