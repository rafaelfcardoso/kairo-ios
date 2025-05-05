# Background and Motivation
Enable users to create tasks through a chat interface. When a user expresses intent to create a task in chat, the system should:
- Start a new chat session/context.
- Use the LLM to process the user’s intent and call the MCP client to create a new TodoTask.
- Ensure the dashboard/task list logic is not changed unless required.

# Background and Motivation (updated)

We have identified a critical architectural issue: the chat overlay (GlobalChatInput) is currently being rendered both at the app level (ZenithApp.swift) and inside MainView, causing duplicate chat UIs and messages. Additionally, the chat overlay must be globally accessible from any screen (Inbox, Projects, Blocks, etc.), and must not cross navigation/tool bar boundaries.

This refactor will:
- Move the chat overlay to only be rendered at the app (ZenithApp.swift) level.
- Ensure only a single instance of chatViewModel and GlobalChatInput exists app-wide.
- Remove all chat overlay logic from MainView and other views.
- Guarantee the overlay respects safe areas and does not cross the navigation bar.
- Enable any screen to trigger the chat overlay by updating chatViewModel.isExpanded.

# Project Status Board
- [x] Create folders in Xcode following the Target Directory Layout (verify in Xcode navigator).
  - [Completed automatically by Executor at 2025-04-29T12:09:14-03:00]
- [x] Add Swift SDK dependency `modelcontextprotocol/swift-sdk` ≥ 0.7.1 (verify package resolves).
  - [Completed by Executor at 2025-04-29T14:01:17-03:00]
- [x] Implement `ZenithMCP` helper in `Data/MCP` to initialize `HTTPClientTransport` and `Client` (verify helper compiles and exposes singleton API).
  - [Completed by Executor at 2025-04-29T14:01:17-03:00]
- [x] Resolve Xcode build errors: multiple commands producing Info.plist and .keep (ensure only one build phase copies Info.plist, and .keep files are not included in Copy Bundle Resources).
  - [Completed by Executor at 2025-05-02T10:48:06-03:00]
- [x] MCP backend endpoints and checklist from mcp-backend-integration.md are complete and ready for integration.
- [x] Protocol-oriented repositories and use cases for Task entity are implemented (MCP-backed, not yet wired to UI).
- [x] **Validate current application build:**
      - Attempt to build the app in Xcode.
      - If build errors occur, document and resolve them before starting further MCP integration.
- [x] **Integrate Claude Haiku 3.5 LLM API as chat assistant backend**
    - [x] Securely store and use Claude API credentials.
    - [x] Implement networking to send user chat messages to Claude.
    - [x] Receive and display LLM responses in the chat UI (console for now).
    - [x] Parse and handle tool call instructions (e.g., `create-task`).
- [ ] **Integrate MCP client with chat-driven task creation flow:**
      - [ ] Update `GlobalChatViewModel` to handle task creation intent.
      - [ ] Ensure chat session starts when user wants to create a task.
      - [ ] Use the LLM to call the MCP `create-task` tool via the repository/use case.
      - [ ] Ensure only the Presentation layer interacts with the use case, not MCP directly.
      - [ ] **Implement animated transitions and premium chat UX:**
          - [ ] Design animated fade/slide transitions between Task List and Chat UI.
          - [ ] Use shared element transitions (e.g., matchedGeometryEffect) for persistent UI components.
          - [ ] Add visual feedback for assistant “thinking” (typing indicator, shimmer, etc).
          - [ ] Animate chat message bubbles and input focus.
          - [ ] Ensure accessibility (Reduce Motion) and performance best practices.
- [ ] Test the chat-driven task creation end-to-end.
- [ ] Document changes and update scratchpad/architecture docs as needed.
- [ ] Create Repositories and UseCases with protocol-oriented abstractions (verify Presentation layer has no direct MCP imports).
  - [In progress: Executor]
- [ ] Refactor ViewModels to invoke UseCases instead of direct service calls (verify build success).
- [ ] Update `AppState` DI container wiring repositories → use cases → view models (verify dependencies injected).
- [ ] **Robustness, UX, and Maintainability Enhancements (Phase 1)**
    - [ ] Define & enforce a UI state machine for chat flow (`ChatFlowState` enum, refactor flags).
    - [ ] Extract shared ChatInputField with matchedGeometryEffect.
    - [ ] Implement accessibility checks and graceful animation degradation.
    - [ ] Add loading skeleton, shimmer, and offline retry UX for chat.
    - [ ] Write snapshot tests for key chat transitions.
    - [ ] Document new flow/state machine in scratchpad and architecture docs.
- [ ] **Premium Polish & Performance (Phase 2)**
    - [ ] Instrument MCP client and chat for analytics (latency, errors, retries).
    - [ ] Warm up MCP client on launch for premium users.
    - [ ] Benchmark MCP response times (XCTest or Playground).

## Project Status Board (Chat Overlay Refactor)
- [x] Refactor chat overlay to be global (app-level only), removing from MainView and other views.
- [ ] Remove the custom tab bar and all related logic from ZenithApp.swift and any other affected files.
- [ ] Ensure chat overlay respects safe areas and does not cross navigation/tool bar boundaries (now simplified).
- [ ] Test across all screens to confirm no duplication and correct overlay behavior.

## Success Criteria (Chat Overlay Refactor)
- Only one chat overlay/input is ever visible, regardless of screen.
- Chat overlay never crosses navigation/tool bar boundaries (tab bar removed).
- No duplicated chat messages or UI.
- All existing chat and navigation functionality remains intact.

## Planner Note (Tab Bar Removal)

- User has decided the tab bar is unnecessary and can be safely removed from the app.
- Dashboard remains deactivated.
- This will simplify the layout and resolve chat overlay/safe area complexity.

## Planner Note: Local Chat Sessions & History (Pre-Backend)

### Background & Motivation
- User wants a ChatGPT-style chat overlay: each chat is a session, listed in the sidebar as "Past Chats".
- Sessions/history will be local-only for now (no backend sync yet).
- This enables switching between chats, starting new ones, and reviewing past conversations—all before backend support.

### Implementation Plan

#### 1. Data Model
- Define `ChatSession` struct:
  - `id: UUID`
  - `title: String` (first user message or customizable)
  - `messages: [ChatMessage]`
  - `createdAt: Date`
- Extend or create `ChatSessionsViewModel`:
  - `@Published var sessions: [ChatSession]`
  - `@Published var currentSession: ChatSession?`
  - Methods for: new session, select session, append message, delete session, etc.

#### 2. UI: Sidebar Integration
- Add a "Past Chats" section to the sidebar (or a modal if sidebar is not always visible).
- List all sessions by title and/or date (most recent first).
- Add a "New Chat" button at the top of the section.
- Selecting a session loads it into the chat overlay.

#### 3. Chat Overlay Integration
- The chat overlay displays messages for `currentSession`.
- On sending a message, append to `currentSession.messages`.
- On "New Chat":
  - Save current session (if it has messages).
  - Create a new session and set as current.
  - Clear chat input/messages.

#### 4. Persistence (Optional, but recommended for UX)
- Store sessions in `UserDefaults` or local file for now.
- Load sessions on app launch.
- When backend is ready, migrate to remote storage.

#### 5. Edge Cases & UX
- If no session exists, auto-create one on app launch or first message.
- If user deletes a session, remove from list and handle if it was current.
- UI: highlight the active session in sidebar.
- Provide a way to exit/close chat overlay (e.g., X button or swipe down).

### Project Status Board (Chat Sessions & History)
- [ ] Define `ChatSession` data model and `ChatSessionsViewModel`.
- [ ] Integrate session management into chat overlay and sidebar.
- [ ] Implement "New Chat" and session selection UX.
- [ ] (Optional) Add local persistence for sessions.
- [ ] Add UI affordance to exit/close chat overlay.
- [ ] Test: create, switch, delete, and persist chat sessions.

### Success Criteria
- User can start new chats, switch between past chats, and see chat history in the sidebar.
- Each chat session maintains its own message history.
- Chat overlay can be exited/closed, returning to main content.
- (Optional) Chat sessions persist across app restarts.

### Debugging: SwiftUI Type-Check Error
- Issue: Compiler unable to type-check a complex SwiftUI expression in `ZenithApp.swift` at line 269.
- Plan:
  1. Open `ZenithApp.swift` at the WindowGroup body starting at line 269.
  2. Identify deeply nested closures: `GeometryReader` → `ZStack` → `Group` → `switch` → etc.
  3. Extract the entire inner view (from `GeometryReader { ... }`) into a new subview, e.g. `AppMainView: View`.
     - Move all logic inside `GeometryReader` into `AppMainView`, passing necessary state bindings and view models.
  4. Similarly extract the custom tab bar content into its own `CustomTabBarView`.
  5. In `ZenithApp.swift`, replace the long body with:
     ```swift
     WindowGroup {
         AppMainView(
             taskViewModel: taskViewModel,
             focusViewModel: focusViewModel,
             projectViewModel: projectViewModel,
             keyboardHandler: keyboardHandler,
             chatViewModel: chatViewModel,
             showingSidebar: $showingSidebar,
             selectedProject: $selectedProject,
             selectedTab: $selectedTab
         )
     }
     ```
  6. Break up long modifier chains by assigning intermediate views to variables or using computed properties:
     ```swift
     let mainView = MainView(...)
         .environmentObject(...) // etc.
     mainView
         .blur(...) // apply modifiers
     ```
  7. Re-run the build. The compiler should now be able to type-check quickly.

# Executor's Feedback or Assistance Requests
- Build validated, proceeding with MCP chat-driven task creation integration as planned.
- Starting refactor: Chat UI will become a first-class screen (not overlay), so navigation/sidebar is always accessible. Chat sessions will be managed as screens, not modals.

# Lessons
- Naming collisions with Swift's Task type require using TodoTask consistently across all layers.
- MCPHTTP is not required if using only MCP; HTTPClientTransport is included in MCP as of SDK v1.8+.
- Always clean build folder after dependency or import changes.
- Rendering stateful overlays in multiple places leads to duplication and race conditions. Always centralize global overlays at the app level when global access is needed.

# Next Steps
