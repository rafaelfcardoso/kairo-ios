
# TaskRepositoryMCP Implementation Clarifications

This document consolidates the **definitive guidance** for implementing `TaskRepositoryMCP.swift`
and its unit‐tests, based on an accurate reading of the MCP Swift SDK.

---

## 1  Purpose

* Eliminate the remaining uncertainties around argument construction, error handling and
  response decoding for the `create-task` tool call.
* Provide ready‑to‑paste Swift snippets and a checklist for bringing the data layer and its
  tests fully in line with the SDK.

---

## 2  Quick Verdict

| Topic | Correct Approach | Common Pitfall |
|-------|------------------|----------------|
| **Arguments** | Keep dictionary typed **`[String : Value]`**.<br>Primitives are accepted thanks to literal conformances. | Changing the type to `[String : Any]`, which loses static safety. |
| **Errors** | `MCPError.code` is a **`String`**; switch on string literals. | Assuming it is an enum and attempting to cast. |
| **Tool.Content** | Tools that return structured JSON should use **`.object([String: Value])`**.<br>Handle `.text(String)` as a fallback. | Assuming *only* `.text(String)` is possible. |
| **Helpers** | A helper for turning a `[String: Value]` object into `Data` is still useful. | Deleting helper methods altogether. |

---

## 3  Detailed Notes & Rationale

### 3.1  Argument Construction

```swift
var args: [Value] = [
    "title": .string(title),
    "description": .string(desc) // when present
]
```

*`Value` is `ExpressibleByStringLiteral`, `ExpressibleByIntegerLiteral`, etc., so the explicit
`.string(...)` is optional but self‑documenting.*

### 3.2  Error Handling

`MCPError` is declared roughly as:

```swift
public struct MCPError: Error, Sendable {
    public let code: String
    public let message: String?
}
```

Therefore:

```swift
catch let err as MCPError {
    switch err.code {
    case "InvalidParams":  ...
    case "Unauthorized":   ...
    default:               ...
    }
}
```

### 3.3  Decoding `Tool.Content`

```swift
guard let content = contents.first else {
    throw TaskRepoError.unexpectedResponse("No content returned")
}

let todo: TodoTask
switch content {
case .object(let dict):
    todo = try decodeTodo(from: dict)
case .text(let json):
    guard let data = json.data(using: .utf8) else {
        throw TaskRepoError.responseDecodingFailed(...)
    }
    todo = try JSONDecoder().decode(TodoTask.self, from: data)
default:
    throw TaskRepoError.unexpectedResponse("Unsupported content type: \(content)")
}
```

---

## 4  Revised `createTask` Implementation (excerpt)

```swift
func createTask(title: String, description: String?) async throws -> TodoTask {
    var args: [String : Value] = ["title": .string(title)]
    if let d = description, !d.isEmpty { args["description"] = .string(d) }

    do {
        let (contents, _) = try await mcpClient.callTool(name: "create-task", arguments: args)
        return try decodeTodoContent(contents)

    } catch let err as MCPError {
        switch err.code {
        case "InvalidParams": throw TaskRepoError.invalidArguments(err.message)
        case "Unauthorized":  throw TaskRepoError.authenticationFailed(err.message)
        case "Forbidden":     throw TaskRepoError.accessDenied(err.message)
        case "ServerError":   throw TaskRepoError.serverError(err.message)
        default:              throw TaskRepoError.mcpError(err.localizedDescription)
        }
    }
}
```

*Helper `decodeTodoContent(_:)` performs the `Tool.Content` switch shown in §3.3.*

---

## 5  Unit‑Test Adjustments

1. **Arguments** – still typed `[String : Value]`; literal values compile.
2. **Success path** – mock with  
   ```swift
   mockClient.toolCallResult = .success(([ .object(taskDict) ], false))
   ```
   (Add a second test using `.text(jsonString)` if desired.)
3. **Error path** – construct with  
   `MCPError(code: "InvalidParams", message: "Title is missing", …)`.
4. **Assertions** – unchanged for `lastArguments`; adjust decoding expectations.

---

## 6  Action Checklist

- [ ] Keep `[String : Value]` for arguments.
- [ ] Switch on **string** error codes.
- [ ] Handle both `.object` **and** `.text` when decoding tool results.
- [ ] Move / keep a small helper for converting `[String: Value]` → `Data`.
- [ ] Update tests to reflect the above.

---

### Appendix A  Where does `.object` come from?

`Tool.Content` in the SDK source:

```swift
public enum Content: Sendable {
    case text(String)
    case object([String: Value])
    case image(Data, mimeType: String, metadata: [String: Any]?)
    …
}
```

Hence structured JSON is naturally delivered as `.object`.

---

Happy coding!
