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

---

### Core Infrastructure

- [x] Create folders in Xcode following the Target Directory Layout

  - Status: Done
  - Agent: Executor
  - Success Criteria: All folders present and matched to target layout in Xcode navigator.
  - Dependencies: None
  - Completed: 2025-04-29T12:09:14-03:00

- [x] Add Swift SDK dependency `modelcontextprotocol/swift-sdk` ≥ 0.7.1

  - Status: Done
  - Agent: Executor
  - Success Criteria: SDK resolves in Xcode and is available for import.
  - Dependencies: None
  - Completed: 2025-04-29T14:01:17-03:00

- [x] Implement `ZenithMCP` helper in `Data/MCP` to initialize `HTTPClientTransport` and `Client`

  - Status: Done
  - Agent: Executor
  - Success Criteria: Helper compiles and exposes singleton API.
  - Dependencies: Swift SDK
  - Completed: 2025-04-29T14:01:17-03:00

- [x] Resolve Xcode build errors: Info.plist/.keep

  - Status: Done
  - Agent: Executor
  - Success Criteria: Build succeeds, no duplicate Info.plist or .keep issues.
  - Dependencies: None
  - Completed: 2025-05-02T10:48:06-03:00

- [x] MCP backend endpoints and checklist implemented

  - Status: Done
  - Agent: Executor
  - Success Criteria: All endpoints available and checklist items complete.
  - Dependencies: MCP backend

- [x] Protocol-oriented repositories and use cases for Task entity

  - Status: Done
  - Agent: Executor
  - Success Criteria: Protocols implemented, MCP-backed, not yet wired to UI.
  - Dependencies: MCP backend

- [x] Validate current application build
  - Status: Done
  - Agent: Executor
  - Success Criteria: App builds in Xcode without errors.
  - Dependencies: Above infrastructure

---

### Chat & Session Features

- [x] Integrate Claude Haiku 3.5 LLM API as chat assistant backend

  - Status: Done
  - Agent: Executor
  - Success Criteria: Securely store Claude API credentials, send/receive messages, parse tool calls.
  - Dependencies: Claude API

- [x] Implement ChatGPT-style New Chat Flow (GlobalChatInput & NewChatScreen)

  - Status: Done
  - Agent: Executor
  - Success Criteria: User can start new chat, UI transitions, messages display, session added to history/sidebar.
  - Dependencies: Claude LLM integration

- [ ] Animate the transition for a seamless experience

  - Status: To Do
  - Agent: Executor
  - Success Criteria: UI transitions between chat states are animated and visually smooth.
  - Dependencies: Chat session UI

- [x] Fix: Selecting a past chat session from the sidebar always opens the correct chat overlay/modal

  - Success Criteria: When the user selects any chat session from the sidebar, the chat overlay/modal is presented and displays the correct session, regardless of the current view or navigation state. This works reliably after navigation, app restarts, and across all main screens.
  - Dependencies: ChatSessionsViewModel, SidebarMenu, chat overlay/modal logic

  **Background and Motivation:**
  - Users expect a ChatGPT-style navigation: when a chat is selected from the sidebar, the main content instantly switches to that chat session (no modal, no left-right navigation stack animation). The sidebar should close after selection (like the iOS ChatGPT app). The "New Chat" overlay/modal remains unchanged for now to preserve the current new-chat flow and session title generation.

  **Root Cause:**
  - The previous implementation used a modal overlay for chat sessions, which is not the desired navigation model. Chat sessions should be part of the main content, not presented modally.

  **Best Practice:**
  - Use a single source of truth for the current main content (Today, Project, or ChatSession) at the app/root level. Selecting a chat from the sidebar updates this state, and the sidebar closes.
  - Only use overlays/modals for flows like "New Chat" if necessary.

  **Implementation Steps:**
  1. Refactor AppMainView so the main content region can display Today, Project, or ChatSession based on app state.
  2. Remove .fullScreenCover for chat sessions; display chat in the main content area instead.
  3. Update SidebarMenu's onSelect handler: set the selected chat session and close the sidebar.
  4. Test: Selecting a chat from the sidebar always updates the main content and closes the sidebar. Switching between Today, Project, and Chat works seamlessly.
  5. Leave the "New Chat" overlay/modal flow unchanged for now.

- [x] Generate chat session title after LLM response

  - Status: Done
  - Agent: Executor
  - Success Criteria: After LLM replies, session title is generated (using first user message or LLM summary) and shown in sidebar.
  - Dependencies: ClaudeLLMService title generation method

- [x] Persist chat sessions locally (Phase 1: Local-only)

  - Status: Done
  - Agent: Executor
  - Success Criteria: All chat sessions are saved to local storage (UserDefaults/Codable), loaded on app launch, and persist after restarts. Deletion in UI removes from storage.
  - Dependencies: ChatSessionsViewModel persistence

- [ ] Test chat-driven task creation end-to-end

  - Status: To Do
  - Agent: Executor
  - Success Criteria: User can create a task via chat, new session is created, and task is added to backend.
  - Dependencies: Chat session, MCP integration

- [ ] Document changes and update architecture docs
  - Status: To Do
  - Agent: Executor
  - Success Criteria: All changes reflected in scratchpad and architecture docs.
  - Dependencies: Above features

---

### Architecture & Refactoring

- [ ] Create Repositories and UseCases with protocol-oriented abstractions

  - Status: In Progress
  - Agent: Executor
  - Success Criteria: Presentation layer has no direct MCP imports; abstractions in place.
  - Dependencies: MCP backend, protocol definitions

- [ ] Refactor ViewModels to invoke UseCases instead of direct service calls

  - Status: To Do
  - Agent: Executor
  - Success Criteria: ViewModels depend on UseCases only, app builds and runs.
  - Dependencies: UseCases, repositories

- [ ] Update `AppState` DI container to wire repositories → use cases → view models
  - Status: To Do
  - Agent: Executor
  - Success Criteria: All dependencies injected via DI container, app builds and runs.
  - Dependencies: Above refactorings

---

### Premium Polish & Performance (Phase 2)

### UX, Robustness, and Testing

- [ ] Define & enforce a UI state machine for chat flow (`ChatFlowState` enum, refactor flags)

  - Status: To Do
  - Agent: Executor
  - Success Criteria: Chat flow logic is managed via a single state machine, all flags refactored.
  - Dependencies: Chat UI

- [ ] Extract shared ChatInputField with matchedGeometryEffect

  - Status: To Do
  - Agent: Executor
  - Success Criteria: ChatInputField is reusable and animates smoothly between screens.
  - Dependencies: Chat UI

- [ ] Implement accessibility checks and graceful animation degradation

  - Status: To Do
  - Agent: Executor
  - Success Criteria: App passes accessibility tests, animations degrade gracefully on older devices.
  - Dependencies: Chat UI, animation

- [ ] Add loading skeleton, shimmer, and offline retry UX for chat

  - Status: To Do
  - Agent: Executor
  - Success Criteria: Loading and offline states have skeleton/shimmer, retry works offline.
  - Dependencies: Chat UI

- [ ] Write snapshot tests for key chat transitions

  - Status: To Do
  - Agent: Executor
  - Success Criteria: Snapshot tests cover chat transitions and catch regressions.
  - Dependencies: Chat UI

- [ ] Document new flow/state machine in scratchpad and architecture docs
  - Status: To Do
  - Agent: Executor
  - Success Criteria: Docs updated to reflect new chat state machine and flow.
  - Dependencies: Above refactorings

## Implementation Notes

- See previous implementation plan and architecture docs for details on persistence, chat overlay, and sidebar integration.
- For detailed success criteria and edge cases, refer to the "Success Criteria" and "Implementation Plan" sections below.

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
- [x] Implement ChatGPT-style New Chat Flow (GlobalChatInput & NewChatScreen UI and logic)
- [x] Update `GlobalChatViewModel` to start and select a new chat session on send
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

- [2025-05-10 16:59] The session is now always added to chat history and the sidebar updates as soon as a new chat is started. After the Claude reply, the session title is generated and the sidebar reflects the new title. Debug prints were added for traceability. Next: Animate the transition for a seamless experience.

- The GlobalChatViewModel has been refactored to support new chat session creation via the ChatSessionsViewModel. The next step is to ensure the UI (GlobalChatInput and navigation logic) triggers the transition to the NewChatScreen with the new session active.
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
