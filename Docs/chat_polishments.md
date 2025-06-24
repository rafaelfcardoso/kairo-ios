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

  #### Phase 2: Premium Enhancements

- [ ] Implement subtle transition from GlobalChatInput send to NewChatScreen overlay
- [ ] Animate the overlay transition for a seamless UX
- [ ] Add XCUITest for overlay transition and keyboard dismissal edge cases
- [ ] Add local persistence for chat sessions (UserDefaults or local file)
