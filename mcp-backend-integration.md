# MCP Backend Integration: Requirements for Zenith Frontend

This document outlines the requirements and expectations the Zenith iOS front end has for the MCP backend server. It is intended for backend developers to ensure seamless communication between the MCP Swift client and the custom Zenith MCP server.

---

## 1. Endpoint & Protocol

- **URL:** The backend must expose an HTTP(S) endpoint for MCP protocol requests (e.g., `/mcp`).
- **Protocol:** Must fully implement the Model Context Protocol (MCP) as per the official [specification](https://modelcontextprotocol.info/docs/quickstart/client/).
- **Transport:** Supports HTTP(S) with Server-Sent Events (SSE) for streaming.

## 2. Authentication

- **Bearer Token:** The frontend will send an `Authorization: Bearer <token>` header on requests (if authenticated).
- **401/403 Handling:** The server must return proper HTTP status codes and error messages for unauthorized/forbidden requests.

## 3. Expected Requests from Frontend

- **Initialization:** The client will call `client.connect(transport: HTTPClientTransport(endpoint: ...))` and `client.initialize()`.
- **Tool Calls:** The frontend will invoke tools using `client.callTool(name:arguments:)`.
- **Resource Access:** The frontend may call `client.listResources()`, `client.readResource(uri:)`, and subscribe to resource updates.
- **Prompt Usage:** The frontend may call `client.listPrompts()` and `client.getPrompt(name:arguments:)`.

## 4. Response Format

- **MCP JSON:** All responses must strictly follow the MCP JSON-RPC format.
- **Streaming:** For streaming endpoints, use SSE for real-time updates.
- **Error Handling:** Return clear MCP-compliant error objects for failed requests.

## 5. CORS & Networking

- **CORS:** If the frontend is served from a different domain, ensure CORS headers allow requests from the app’s origin.
- **HTTPS:** Production endpoints must use HTTPS.

## 6. Versioning & Metadata

- **Version:** The server should expose its MCP protocol version and capabilities in the initialization handshake.
- **App-specific Metadata:** Optionally include custom metadata (e.g., server name, supported tools, etc.) in the handshake response.
- **Client Version:** The frontend will include its MCP client version in `initialize.params.clientVersion`. If the server cannot support that major version, it must return error code `IncompatibleVersion` with HTTP 426.

## 7. Rate‑Limiting & Back‑Pressure

- The server MAY respond with **HTTP 429** (Rate Limited) or **503** (Overloaded).
- For SSE streams, include a `retry: <milliseconds>` field to tell the client when to reconnect.

## 8. Tool Argument Schemas

Every tool should publish its JSON Schema (or equivalent zod schema) in the `initialize` capabilities so the client can validate arguments locally.

**Example for `create-task`:**

```json
"tools": {
  "create-task": {
    "argumentsSchema": {
      "type": "object",
      "properties": {
        "title": { "type": "string" },
        "description": { "type": "string" }
      },
      "required": ["title"]
    }
  }
}
```

## 9. Error Code Mapping

| MCP Error             | HTTP Code | Meaning                            |
| --------------------- | --------- | ---------------------------------- |
| `InvalidParams`       | 400       | Bad request / schema mismatch      |
| `Unauthorized`        | 401       | Missing or bad token               |
| `Forbidden`           | 403       | Authenticated but lacks permission |
| `NotFound`            | 404       | Resource not found                 |
| `RateLimited`         | 429       | Too many requests                  |
| `ServerError`         | 500       | Unexpected backend error           |
| `IncompatibleVersion` | 426       | MCP version mismatch               |

## 10. Example: Initialization Flow

```http
POST /mcp HTTP/1.1
Authorization: Bearer <token>
Content-Type: application/json

{
  "jsonrpc": "2.0",
  "method": "initialize",
  "params": { ... },
  "id": 1
}
```

**Expected response:**

```json
{
  "jsonrpc": "2.0",
  "result": {
    "capabilities": { ... },
    "serverInfo": { "name": "Zenith MCP Server", "version": "1.0.0" }
  },
  "id": 1
}
```

---

## 11. Checklist for Backend Developers

- [x] Expose an HTTP(S) endpoint for MCP (e.g., `/mcp`).
- [x] Implement all required MCP methods (`initialize`, `callTool`, etc.).
- [x] Support SSE for streaming responses.
- [x] Validate and handle Bearer authentication.
- [x] Return correct MCP JSON-RPC responses and errors.
- [x] Document the endpoint URL and capabilities for frontend integration.
- [x] Implement version negotiation (client ↔ server) as described in §6.
- [x] Return HTTP 429 / 503 and SSE `retry` for back‑pressure scenarios.
- [x] Publish JSON schemas for every tool in the `initialize` handshake.
- [x] Follow the Error Code Mapping table for consistent responses.

---

## Integration Notes & Lessons Learned (2025‑04‑30)

- **Deprecation:** The MCP SDK v1.8+ removed `McpServer.handleJsonRpc`. Use `StreamableHTTPServerTransport.handleRequest` for all HTTP/SSE endpoints.
- **Headers:** All POST `/mcp` requests must include:
  - `Authorization: Bearer <token>` (if authenticated)
  - `Content-Type: application/json`
  - `Accept: application/json`
- **Error Mapping:** Error code mapping now strictly follows the table below. E2E tests verify each scenario:

| MCP Error             | HTTP Code | Meaning                            |
| --------------------- | --------- | ---------------------------------- |
| `InvalidParams`       | 400       | Bad request / schema mismatch      |
| `Unauthorized`        | 401       | Missing or bad token               |
| `Forbidden`           | 403       | Authenticated but lacks permission |
| `NotFound`            | 404       | Resource not found                 |
| `RateLimited`         | 429       | Too many requests                  |
| `ServerError`         | 500       | Unexpected backend error           |
| `IncompatibleVersion` | 426       | MCP version mismatch               |

- **406 Not Acceptable:** If you see 406 errors, check that both `Content-Type` and `Accept` headers are set to `application/json` in all client and test requests.
- **Testing:** E2E tests for all error scenarios are in `test/e2e/mcp-errors.e2e-spec.ts`. Run with:
  ```
  npx jest --config ./test/jest-e2e.config.ts test/e2e/mcp-errors.e2e-spec.ts
  ```
- **SSE Streaming:** For GET `/mcp`, the client must use `Accept: text/event-stream`.

---

For further details, see the [MCP Swift SDK documentation](https://github.com/modelcontextprotocol/swift-sdk) and the [MCP protocol spec](https://modelcontextprotocol.info/docs/quickstart/client/).
