# Background and Motivation

The Today screen and sidebar projects are failing to load due to repeated 401 Unauthorized errors. We need to implement a full authentication flow (login UI, login API call, token persistence) and integrate it into the networking layer before fetching any data. Once authenticated, tasks and projects should load correctly with existing caching and error-handling logic.

# Project Status Board

- [x] Create `AuthViewModel` with `email`, `password`, `isLoading`, `errorMessage`, and `login()` method.
- [x] Create `LoginView` (SwiftUI) with email/password fields and “Sign In” button, bound to `AuthViewModel`.
- [x] Implement `AuthService.login(email:password:) async throws -> AuthResponse` calling `POST /api/v1/auth/login`.
- [x] Persist bearer token securely in `APIConfig` (and/or Keychain).
- [x] Enhance `APIConfig.addAuthHeaders(to:)` to inject `Authorization: Bearer <token>` header.
- [x] Update `TaskViewModel` (and other ViewModels) to require authentication before calling `loadTasks()` and related APIs.
- [x] Modify the root SwiftUI App view to present `LoginView` when no valid token exists, otherwise show main content.
- [x] Add end-to-end XCUITest for login flow and successful Today-screen data loading.
- [x] Stub login API in UI-tests with a launch argument to return a fake token.
- [x] Assign accessibility identifiers (`EmailField`, `PasswordField`, `SignInButton`, `TodayGreeting`).
- [x] Update `AuthFlowUITests` to use these identifiers and stubbed login.
- [x] Fix `AuthResponse` decoding to match actual API JSON.
- [x] Implement `-reset-auth` launch argument handling to clear stored token on startup.
- [ ] Re-run UI tests and ensure all pass.

# Executor's Feedback or Assistance Requests

- [x] `AuthService.login(email:password:)` implemented at `Zenith/Services/AuthService.swift`. Ready for token persistence and integration with APIConfig.
- [x] Token is now persisted securely via Keychain in `APIConfig`. Ready for integration with API headers and auth flow.
- [x] TaskViewModel now requires authentication before loading tasks. Ready for root view switching logic.
- [x] Root SwiftUI App view now presents LoginView if not authenticated, otherwise shows main content. Ready for E2E testing.
- [ ] UI-tests are stubbed, identifiers added, and decoding fixed. Ready to rerun tests.

# Lessons

- Follow E2E testing (XCUITest) first; unit tests only when critical for QA.

# Next Steps

- [ ] Add accessibility identifiers to `LoginView.swift` (EmailField, PasswordField, SignInButton).
- [ ] Verify `LoginView` updates `APIConfig.authToken` and triggers MainView transition.
- [ ] Ensure `TaskViewModel.refreshAfterLogin()` runs on appear.
- [ ] Re-run UI tests and confirm `TodayGreeting` loads.
- [ ] Investigate and fix any remaining UI-test failures.
- [ ] Extract and store logged-in user's name from `AuthResponse` in `AuthViewModel`.
- [ ] Update sidebar UI to display dynamic user name.
- [ ] Present settings modal sheet when tapping the gear button.
- [ ] Add a “Log Out” button in the settings modal.
- [ ] Implement logout logic to clear `APIConfig.authToken` and reset app to Sign In screen.
