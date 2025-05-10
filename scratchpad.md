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

## Background and Motivation
The app must show a login modal when an API call returns 401 Unauthorized. Currently, some 401s are not mapped to `.unauthorized` and thus do not trigger the modal, breaking the user experience.

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
- [ ] **Implement ChatGPT-style New Chat Flow (GlobalChatInput & NewChatScreen UI and logic):**
    - [x] Update `GlobalChatViewModel` to support new chat session creation from the global chat input.
    - [ ] On user prompt submission, create a new `ChatSession` and add the user's message.
    - [ ] Transition UI to `NewChatScreen` with the new session active.
    - [ ] Display user's message and AI response in the new session.
    - [ ] Ensure session is added to chat history and accessible from sidebar.
    - [ ] Animate the transition for a seamless experience.
    - [ ] (Optional) Persist chat sessions locally.
    - **Success Criteria:**
        - User prompt in global input creates a new chat session.
        - UI transitions to `NewChatScreen` with the session active.
        - User and AI messages appear correctly.
        - New session is tracked in chat history/sidebar.
        - Visual and functional flow matches ChatGPT-style UX.
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
- [ ] 1. Audit all networking code (especially in `FocusSessionViewModel`) for cases where 401 errors are mapped to `.invalidResponse` or not mapped at all.
- [ ] 2. Refactor these cases so that 401 always throws `APIError.unauthorized` (or `.authenticationFailed`).
- [ ] 3. Ensure all ViewModels that make API calls (especially `FocusSessionViewModel`) set `authViewModel?.requiresLogin = true` on `.unauthorized` and `.authenticationFailed` errors, just like in `TaskViewModel`.
- [ ] 4. Test by simulating a 401 error and confirm the login modal appears.
- [ ] 5. Update `scratchpad.md` with the error-handling pattern for future reference.
- [ ] Test new detailed error logging in TaskViewModel for all task-related API calls (overdue, all tasks, etc.)
- [ ] Confirm that all authentication failures trigger the login modal and are clearly logged.
- [ ] Review logs for non-authentication errors and document any recurring issues or patterns.
- [ ] Remove all API debugging logs from ViewModels and related files (keep only essential error/user-facing logs).
- [ ] Remove FocusSessionViewModel debug logs.
- [ ] Refactor Focus Session modal logic in TaskFormView: use a @State var to control modal visibility and present FocusSessionView using .sheet or .fullScreenCover. Remove UIKit rootVC.present logic for SwiftUI-native modal presentation.
- [ ] Fix: Focus session modal does not show when tapping "Iniciar Sessão de foco" (ensure state and sheet logic is correct and integrated with FocusSessionViewModel).

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
#### Phase 1: Essential Implementation
- [x] Define `ChatSession` model and `ChatSessionsViewModel` with session management
- [ ] Implement ChatGPT-style New Chat Flow (GlobalChatInput & NewChatScreen UI and logic)
- [ ] Update `GlobalChatViewModel` to start and select a new chat session on send
- [ ] Integrate session management into chat overlay and sidebar
- [ ] Add basic XCUITest for chat send and keyboard dismissal
- [ ] Add UI test to verify AI responses appear correctly in chat session UI
- [ ] Add unit test for GlobalChatViewModel response-handling logic

#### Phase 2: Premium Enhancements
- [ ] Implement subtle transition from GlobalChatInput send to NewChatScreen overlay
- [ ] Animate the overlay transition for a seamless UX
- [ ] Add XCUITest for overlay transition and keyboard dismissal edge cases
- [ ] Add local persistence for chat sessions (UserDefaults or local file)

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
- The Start Focus Session button has been added to TaskFormView and is visually prominent. It currently prints a debug message and is ready for integration with FocusSessionViewModel. Next, integration logic is required.

## Project Status Board
- [x] Add a prominently styled "Iniciar sessão de foco" (Start Focus Session) button at the bottom of the main VStack in TaskFormView, just above the @ViewBuilder parameterButton. The button should be full-width, visually distinct, and ready for integration with FocusSessionViewModel (currently prints a debug message).
- [ ] Integrate the "Iniciar sessão de foco" (Start Focus Session) button in TaskFormView with FocusSessionViewModel to actually start a focus session for the selected task.

## Lessons
- Always map HTTP 401 to `APIError.unauthorized` to ensure user-facing authentication handling works.
- Centralize authentication error handling in ViewModels using `authViewModel?.requiresLogin = true` for a consistent user experience.
- When adding UI actions that require view model integration, always scaffold the button first with a debug print, then wire up the actual logic in a separate step for easier testing and review.
- Naming collisions with Swift's Task type require using TodoTask consistently across all layers.
- MCPHTTP is not required if using only MCP; HTTPClientTransport is included in MCP as of SDK v1.8+.
- Always clean build folder after dependency or import changes.
- Rendering stateful overlays in multiple places leads to duplication and race conditions. Always centralize global overlays at the app level when global access is needed.

## Background and Motivation
The user wants to enhance the chat overlay and focus session experience. The TaskFormView should allow users to directly start a focus session for a selected task. The UI should be clean, responsive, and maintain robust interactions. The custom tab bar has been removed, and the new entry point for focus sessions is a dedicated button in the task modal.

# Next Steps

### Success Criteria
- All 401 errors from the API are mapped to `.unauthorized` or `.authenticationFailed`.
- All relevant ViewModels set `authViewModel?.requiresLogin = true` when these errors occur.
- The login modal appears reliably when a 401 is encountered, regardless of which API call fails.

## Executor's Feedback or Assistance Requests

- The GlobalChatViewModel has been refactored to support new chat session creation via the ChatSessionsViewModel. The next step is to ensure the UI (GlobalChatInput and navigation logic) triggers the transition to the NewChatScreen with the new session active.

- Created NewChatScreen as a unified chat screen with toolbar and global chat input, to be shown when tapping the new chat icon in the sidebar.
- [ ] Wire up the sidebar menu "new chat" button to present this screen as a global overlay (not navigation stack or modal), similar to ChatGPT.
- [ ] Ensure chat session is only created after user sends a message; add to history then.
- [ ] Remove the old chat overlay logic for "new chat" if necessary.
- [ ] Test for visual and functional consistency.
- No blockers so far.

- ChatScreen now uses UnifiedToolbar in the navigation bar (via .toolbar), ensuring consistent styling with MainView.
- Sidebar button is always present and functional, using the same animation and haptic feedback as MainView.
- Lesson: To ensure toolbar consistency across screens, always render UnifiedToolbar inside the navigation bar using .toolbar { ToolbarItem(placement: .principal) { ... } }.
- Lesson: Sidebar button must be wired to a shared @Binding var (e.g., showingSidebar) for global sidebar control.
- No blockers encountered. Ready to proceed with Project view refactor. to use shared components, and integrate ChatInputField where applicable.
- No blockers encountered; components compile and integrate cleanly in MainView.

- Enhanced TaskViewModel with standardized, source-specific API error and status code logging.
- All .unauthorized/.authenticationFailed errors now reliably trigger the login modal and are clearly logged.
- Please test and report any non-authentication errors for further investigation.

## Lessons
- Consistent, source-prefixed logging for API responses dramatically improves debugging and root cause analysis.
- Always update UI state (e.g., requiresLogin) on the main actor to avoid concurrency issues.
- Standardizing error handling patterns across ViewModels prevents silent failures and improves user experience.

## Background and Motivation
The goal is to robustly handle API authentication errors, ensure the user is prompted for re-authentication when needed, and make all error sources transparent through detailed logging. This supports a seamless user experience and efficient debugging.

---

## Planner Note: Unified Toolbar & Chat Input (All Major Screens)

### Background & Motivation
- User wants a consistent, professional navigation and chat experience across all major screens (Main, Chat, Projects/Inbox).
- This means every screen should have:
  - The same top Toolbar (with sidebar/hamburger button and dynamic title).
  - The same bottom ChatInputField (for new chats/messages).
- This matches the ChatGPT/Notion/Slack pattern and makes the app easier to maintain and extend.

### Implementation Plan

#### 1. Extract Shared Components
- [x] **UnifiedToolbar**
  - Contains sidebar/hamburger button (always left-aligned).
  - Takes a dynamic title prop: greeting, project name, or chat session name.
  - Optional: right-side actions (settings, etc.).
- [x] **ChatInputField**
  - Single source of truth for chat input UI/logic.
  - Used in MainView, Chat overlay, and Project/Inbox screens.
  - Optional: support matchedGeometryEffect for smooth transitions.

#### 2. Refactor All Screens
- [x] **MainView**: Replace toolbar and chat input with shared components.
- [x] Refactor ChatScreen to use UnifiedToolbar in the navigation bar, matching MainView.
- [x] Ensure the sidebar button is always present and functional in ChatScreen toolbar.
- [x] Present ChatScreen as a seamless overlay in AppMainView, not a separate NavigationStack, for unified sidebar + chat UX.
- [ ] Refactor Project and Inbox views to use UnifiedToolbar and ChatInputField.
- [ ] Test the application thoroughly to confirm that all navigation and chat functionalities work as intended.

#### 3. Consistency & Animation
- [ ] All screens have toolbar at top and chat input at bottom (unless intentionally hidden).
- [ ] Chat input and toolbar animate in sync with sidebar transitions.

#### 4. Accessibility & Polish
- [ ] Ensure all toolbars and chat inputs are accessible (VoiceOver, labels, etc.).
- [ ] Test for visual consistency and smooth animation on all device sizes.

#### 5. Documentation
- [ ] Document the unified layout/component pattern here and in architecture docs for future contributors.

---

**Success Criteria:**
- Every major screen has the same navigation and chat input structure.
- Sidebar can always be opened via toolbar button.
- Chat input is consistent everywhere (UI, logic, animation).
- Easy to maintain and extend.

---
