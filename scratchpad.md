# Background and Motivation
The primary goal is to enable users to create tasks by stating their intent in natural language within the chat interface. The system should leverage the LLM (Claude) to understand this intent, extract relevant task parameters (title, description), and then use the existing `TaskService` to create the task. This involves enhancing the LLM interaction logic and integrating it with the task creation backend.

# Key Challenges and Analysis
- **LLM Prompt Engineering:** Crafting effective prompts for the LLM is crucial for accurate intent detection and parameter extraction. The prompt needs to instruct the LLM to identify task creation requests and return structured data (e.g., JSON) without compromising its general conversational abilities.
- **Structured Data from LLM:** Ensuring the LLM reliably outputs data in a parseable format (e.g., JSON) for task parameters.
- **Integration with Existing Chat Flow:** Modifying `GlobalChatViewModel` and `ClaudeLLMService` to incorporate this new intent detection step without disrupting existing chat functionalities.
- **Client-Side vs. Server-Side (MCP) Logic (New Analysis based on Step 143-144):
  - Anthropic's API supports system prompts and JSON output, technically validating a client-side implementation in `ClaudeLLMService.swift`.
  - Emerging "Model Context Protocol" (MCP) philosophy suggests that if an MCP server layer is responsible for agentic orchestration and tool use, complex prompting for intent detection might better reside on such a server.
  - **Decision for Now:** Proceed with client-side implementation in `ClaudeLLMService.swift` for pragmatic progress and to keep changes localized to the application. However, this is flagged as an architectural consideration: if Zenith's architecture includes/evolves an intermediary MCP server for complex agentic flows, this intent logic might be a candidate for migration to that server.
- **Accessing TaskViewModel:** `GlobalChatViewModel` will need access to an instance of `TaskViewModel` to invoke `createNewTask`.

# High-level Task Breakdown

- [x] Expose `createTask` use-case to presentation (Steps 69-122)
  - [x] Implement `TaskServiceProtocol` and `TaskService` for `createTask`.
    - **Status:** Completed (Steps 69, 71, 74).
    - **Success:** `TaskService` correctly uses `TaskRepositoryProtocol` to create tasks, returning a `TodoTask`.
  - [x] Unit test `TaskService.createTask`.
    - **Status:** Completed (Steps 87, 94).
    - **Success:** Tests cover success, validation failure, and repository errors.
  - [x] Inject `TaskService` into `TaskViewModel` (Manual DI).
    - **Status:** Completed (Steps 120, 122).
    - **Success:** `TaskService` is injected; `TaskViewModel` has `createNewTask` method.

- [x] Configure LLM Service to detect task creation request and extract parameters from messages.
   - **Status:** Completed
   - [x] Define JSON structure for LLM to output upon detecting task creation intent (and for general conversation).
   - [x] Design system prompt for `ClaudeLLMService` instructing Claude on intent detection and JSON output.
   - [x] Implement new method in `ClaudeLLMService` (e.g., `detectIntentAndRespond`) using system prompt, conversation history, and parsing the JSON response.
     - **Success Criteria:** Method correctly sends appropriate prompts and history to Claude, and can parse the expected JSON output for both task creation and general responses.
   - [x] Modify `GlobalChatViewModel` to use the new `ClaudeLLMService.detectIntentAndRespond` method.
     - **Success Criteria:** `GlobalChatViewModel` correctly passes user messages and conversation history.
   - [x] Determine mechanism for `GlobalChatViewModel` to access `TaskViewModel`.
   - [x] Implement logic in `GlobalChatViewModel` to handle the structured intent response:
       - If task creation intent: Call `taskViewModel.createNewTask(title:description:)` and append a confirmation message to chat.
       - If general conversation: Append LLM's reply to chat as usual.
     - **Success Criteria:** Tasks are created when intent is detected; chat functions normally otherwise.
   - [ ] Unit test the new `ClaudeLLMService` method (mocking API, verifying prompt, testing JSON parsing).
   - [ ] Unit test `GlobalChatViewModel`'s new intent handling logic.
   - **Success (Overall for this parent task):** User messages like "Create a task to buy milk" result in a task being created and a confirmation in chat, while other messages lead to normal chat replies. Unit tests for new logic pass.

- [ ] Trigger `createTask` from agent pipeline
  - After Claude reply, pipe structured JSON to `TaskService`
  - **Success:** Manual test shows tasks appear in UI when user asks agent to "create task ..."

- [ ] E2E test: agent creates task
  - XCUITest covers typing request, waits for agent, verifies task list contains new item
  - **Success:** Test passes on CI

# Project Status Board
- [x] Update ZenithMCP for SDK 0.8.2 compatibility
  - Replace `NetworkTransport` with `HTTPClientTransport` pointing to `/mcp` endpoint
  - Use `APIConfig.authToken` from KeychainHelper for authorization headers
  - Configure proper HTTP headers including: Authorization, Content-Type, Accept
  - Add error handling for MCP connection failures
  - **Success:** `ZenithMCP.shared.client.initialize()` succeeds against dev server

- [x] Support `create-task` tool in data layer
  - Implement `TaskRepositoryMCP.createTask(title:description:)` that wraps `client.callTool`
  - Ensure arguments JSON payload **strictly matches** the schema spec in `mcp-backend-integration.md` for `create-task` (required `title`, optional `description`)
  - Handle successful responses and map them to domain models (e.g., `Task`)
  - Implement robust error handling for MCP-defined errors (`InvalidParams`, `Unauthorized`, `ServerError`, etc.) and map them appropriately.
  - **Success:** 
    - [x] Unit test asserts correct `create-task` JSON payload generation based on input `title` and `description`.
    - [x] Unit test verifies correct parsing of mocked successful MCP responses into `Task` domain model.
    - [x] Unit test demonstrates appropriate error handling for various mocked MCP error responses.

- [x] Refine TaskRepositoryMCP and its tests based on clarifications
  - **Status:** Completed (Step 37).
  - **Summary:** Implemented `createTask` in `TaskRepositoryMCP` to call MCP's `create-task` tool, decode `TodoTask` from the response (initially assumed `MCP.Value.object` payload via `jsonData()` helper), and handle MCP errors by mapping them to `TaskRepoError` cases. Added comprehensive unit tests in `TaskRepositoryMCPTests.swift` using a `MockClient` to cover success, various error types (`InvalidParams`, `Unauthorized`), and unexpected/malformed responses.
  - **Refinement (Steps 52, 58):** Further refined `TaskRepositoryMCP.swift` and `TaskRepositoryMCPTests.swift` based on definitive guidance from `Zenith/Docs/TaskRepositoryMCP_Clarifications.md`.
      - `TaskRepositoryMCP.swift`: Adjusted `createTask` to primarily expect `Tool.Content.text(jsonString)` for the `TodoTask` payload and updated `MCPError` handling to switch on string codes (e.g., `"InvalidParams"`).
      - `TaskRepositoryMCPTests.swift`: Updated `testCreateTask_Success_DecodesResponse` to mock `Tool.Content.text(jsonString)`. Added `testCreateTask_Error_UnexpectedResponse_WrongContentType` for non-text content. Modified `testCreateTask_Error_ResponseDecodingFailed` to use a malformed JSON string within `Tool.Content.text`.
  - **Outcome:** Data layer support for `create-task` is now robustly implemented and tested according to confirmed SDK specifications.

- [x] Expose `createTask` use-case to presentation
  - [x] Add `TaskService.createTask`.
    - **Status:** Completed (Steps 73, 75, 92).
    - **Summary:** 
      - Created `TaskServiceProtocol.swift` defining `createTask(title:description:) async throws -> TodoTask`.
      - Created `TaskService.swift` implementing the protocol. It depends on `TaskRepositoryProtocol`, calls the repository's `createTask`, and returns the `TodoTask` (which serves as the domain model in this context).
      - Corrected `TaskRepositoryProtocol.swift`'s `createTask` signature to align with actual usage (`func createTask(title: String, description: String?) async throws -> TodoTask`).
  - [x] Unit test `TaskService.createTask`.
    - **Status:** Completed (Steps 87, 94).
    - **Summary:** 
      - Created `TaskServiceTests.swift` with a `MockTaskRepository`.
      - Added tests for successful creation, validation failure (empty title), and error propagation from the repository.
      - Refined `testCreateTask_Failure_RepositoryError` to use the actual `TaskRepoError.serverError` for more accurate testing.
  - [x] Inject into relevant view models.
    - **Status:** Completed (Steps 120, 122).
    - **Summary:**
      - Investigated DI: Project uses manual DI, primarily in `ZenithApp.swift`.
      - Identified `ZenithMCP.shared.client` as the shared MCP client, simplifying `TaskRepositoryMCP` instantiation.
      - `TaskViewModel.swift`:
        - Added `taskService: TaskServiceProtocol` property.
        - Updated `init()` to accept `taskService`.
        - Added `createNewTask(title:description:) async throws -> TodoTask` method that calls the service.
      - `ZenithApp.swift`:
        - In `init()`, `TaskRepositoryMCP()` and `TaskService(taskRepository:)` are instantiated.
        - `TaskViewModel` is initialized with the `taskService` instance.
    - **Success:** `TaskService` is now injected into `TaskViewModel` and `TaskViewModel` can use it to create tasks. Service returns the expected `TodoTask` domain model. The `TaskService` is resolvable within this manual DI setup.

- [x] Define JSON structure for LLM intent detection response (`LLMIntentResponse`, `LLMTaskDetails`, `LLMIntentType`).
- [x] Design system prompt for `ClaudeLLMService` to guide intent detection and JSON output.
- [x] Implement `detectIntentAndRespond` method in `ClaudeLLMService.swift` (including new Codable structs and system prompt).
- [x] Add `TaskViewModel` as a dependency to `GlobalChatViewModel` and inject it in `ZenithApp.swift`.
- [x] Modify `GlobalChatViewModel.sendMessageToCurrentSession` to use `detectIntentAndRespond`, handle `LLMIntentResponse`, and call `TaskViewModel.createNewTask`.
- [x] Modify `GlobalChatViewModel.startNewChatSession` to use `detectIntentAndRespond`, handle `LLMIntentResponse` (including task creation), and integrate title generation.
- [ ] **Testing (Manual & UI):**
    - [ ] Verify general conversation flow is unaffected.
    - [ ] Test various phrases for task creation (e.g., "Create task: ...", "Remind me to ...", "Add to my list: ...").
    - [ ] Test task creation with and without explicit descriptions.
    - [ ] Check if `assistant_reply` from LLM is appropriate before task creation confirmation.
    - [ ] Check if task creation confirmation/error messages (✅/⚠️) appear correctly.
    - [ ] Verify chat session titles are generated correctly after these interactions.
    - [ ] Test error handling (e.g., simulate API errors, task creation errors).
- [ ] **Unit Tests:**
    - [ ] Write unit tests for `ClaudeLLMService.detectIntentAndRespond` (mocking API responses).
    - [ ] Write unit tests for `GlobalChatViewModel` focusing on:
        - Correct parsing of `LLMIntentResponse`.
        - Correct invocation of `taskViewModel.createNewTask` with extracted parameters.
        - Correct addition of chat messages (assistant reply, task confirmations/errors).
        - Correct conversation history preparation for `detectIntentAndRespond`.
- [ ] Review and refine the system prompt for `ClaudeLLMService` based on testing results for robustness and accuracy.
- [ ] Consider edge cases (e.g., user cancels task creation mid-flow, very long user messages).

# Executor's Feedback or Assistance Requests
- The core implementation for LLM-driven task creation in `ClaudeLLMService` and `GlobalChatViewModel` is complete.
- The immediate next steps involve thorough testing (manual and UI) to ensure the functionality works as expected across various scenarios and to identify any issues with the LLM prompting or response handling.
- Following testing, unit tests should be written to cover the new logic.
- **Request to User:** Please proceed with testing the application. Let me know how the task creation from chat feels and if you encounter any issues or have feedback on the LLM's responses or behavior. Specifically, try different ways of asking to create a task.

# Lessons
- When modifying existing methods that interact with asynchronous services and update UI, ensure all state changes (like `isProcessing`) are correctly managed across different execution paths (success, failure, nested async calls like task creation).
- Carefully manage mutable state (like `ChatSession.messages` and `ChatSession.title`) when updates can come from multiple asynchronous operations (LLM response, task creation, title generation). Fetching the latest state or index of an item in a collection before an update is crucial if the collection could have been modified by another concurrent operation.
- Always ensure `weak` references are used appropriately for ViewModel dependencies to prevent retain cycles, especially `taskVM = self.taskViewModel` in closures.
- Using a specific `sessionID` captured at the beginning of the method is more robust than relying on `currentSession` directly in async callbacks, as `currentSession` might change before the callback executes.

# Open Questions/Items for Planner Review
- The primary mechanism for task creation will be LLM-driven. The next steps focus on configuring the LLM and agent pipeline. Direct UI elements for manual task entry are not the immediate priority for this flow.

# Next Steps (Proposed by Executor)
1.  Begin testing the application to ensure the LLM-driven task creation works as expected.
2.  Write unit tests for the new logic in `ClaudeLLMService` and `GlobalChatViewModel`.
3.  Review and refine the system prompt for `ClaudeLLMService` based on testing results.

# Lessons Learned
- Anthropic's Claude API supports system prompts and can be instructed to provide JSON output, which is beneficial for structured data extraction.
- The "Model Context Protocol" (MCP) is an emerging concept. If Zenith employs an MCP server for orchestrating agentic behavior, complex prompting logic (like intent detection for tool use) might be better suited for that server layer rather than purely client-side. For now, client-side implementation is pragmatic.
- `TaskRepositoryMCP` has a default initializer that conveniently uses a shared MCP client (`ZenithMCP.shared.client`), simplifying its instantiation.

# Open Questions/Items for Planner Review
- **Architectural Consideration:** Should the primary intent detection logic (system prompt for task creation) eventually reside on an MCP server if Zenith's architecture includes/evolves one for such orchestration, aligning with MCP philosophy (reiteration from Key Challenges)?
- **Dependency Access:** How should `GlobalChatViewModel` gain access to `TaskViewModel` to call `createNewTask`? (e.g., direct injection in `ZenithApp.swift` initialization, through `ChatSessionsViewModel`, a shared coordinator, etc.)