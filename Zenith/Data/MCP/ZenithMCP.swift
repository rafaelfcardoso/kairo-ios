import Foundation
import MCP
import Network

/// ZenithMCP provides a singleton/factory for MCP Client configured for Zenith.
final class ZenithMCP {
    static let shared = ZenithMCP()
    let client: Client
    let apiKey = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String

    private init() {
        let connection = NWConnection(
            host: "zenith-api-development.up.railway.app",
            port: 443,
            using: .tls
        )
        let transport = NetworkTransport(connection: connection)
        self.client = Client(name: "Zenith", version: "1.0.0")
        Task {
            // Establish the network connection before using the client
            try? await transport.connect()
            try? await self.client.connect(transport: transport)
            try? await self.client.initialize()
        }
    }

    /// For testing or advanced usage, create a custom instance.
    static func makeCustom(endpoint: URL, name: String = "Zenith", version: String = "1.0.0") -> Client {
        let connection = NWConnection(
            host: NWEndpoint.Host(endpoint.host ?? "localhost"),
            port: NWEndpoint.Port(rawValue: UInt16(endpoint.port ?? 443)) ?? 443,
            using: .tls
        )
        let transport = NetworkTransport(connection: connection)
        let client = Client(name: name, version: version)
        Task {
            try? await transport.connect()
            try? await client.connect(transport: transport)
            try? await client.initialize()
        }
        return client
    }
}
