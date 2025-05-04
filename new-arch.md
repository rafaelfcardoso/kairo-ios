# Front‑end Architectural Refactor (May 2025)

### Goal

Deliver a lightweight but extensible structure that embeds the MCP **Client** inside the iOS **Host** while isolating networking, domain logic, and UI concerns.  
This will let Kairo scale from a solo‑dev MVP to a multi‑module codebase without painful rewrites.

---

## Target Directory Layout

```text
Zenith
├─ App/                  # Entry point + DI (ZenithApp.swift, AppState.swift)
├─ Core/                 # Design system, Config, generic helpers
├─ Data/
│  ├─ MCP/               # Swift SDK wrappers, DTOs, ZenithMCP helper
│  ├─ Remote/            # AuthService, raw REST/SSE utils
│  ├─ Local/             # (optional) persistence
│  ├─ Repositories/      # TaskRepositoryMCP, ProjectRepositoryMCP…
│  └─ Mappers/           # DTO <-> Domain conversions
├─ Domain/
│  ├─ Entities/          # Task, Project, FocusSession…
│  ├─ UseCases/          # CreateTask, ListProjects…
│  └─ Services/          # FocusTimerService, etc.
├─ Presentation/
│  ├─ Features/          # Onboarding, Dashboard, Tasks…
│  └─ SharedUI/          # Toasts, Loaders, generic components
├─ Agents/               # ChatAgent.swift + AgentTools/
└─ Tests/
    ├─ Unit/
    └─ UI/
```

---

## Migration Tasks

1. **Create folders** listed above in Xcode (⌥⌘N) and move existing files:
   - `Components/` → `Presentation/SharedUI`
   - `Services/AuthService.swift` → `Data/Remote`
   - `Models/` → `Domain/Entities`
   - `ViewModels/` → split into `Presentation/Features/...`
   - `Config/` → `Core/Config`
2. **Add dependency**  
   `https://github.com/modelcontextprotocol/swift-sdk.git` (≥ 0.7.1)
3. **Implement `ZenithMCP` helper** in `Data/MCP/` that:
   - builds `HTTPClientTransport`
   - initializes the `Client`
   - exposes a singleton or factory
4. **Create Repositories & UseCases**  
   Use protocol‑oriented abstractions so Presentation never imports MCP directly
5. **Replace direct service calls** in ViewModels with UseCase invocations
6. **Update DI**  
   Add an `AppState` container that wires repositories → use cases → view models
7. **Run & fix imports** until the app builds
8. **Update Unit tests** to mock `TaskRepositoryProtocol`
9. **Smoke‑test**: from the Focus Chat, run `create-task` tool and confirm task appears in Dashboard

---

## Acceptance Criteria

- App compiles & runs with the new structure
- `TaskRepositoryMCP` successfully lists tasks via MCP client
- Existing UI tests (`ZenithUITests`) pass without modification
- No `import MCP` statements outside the `Data/` layer
- This document reflects the implemented architecture (✓)
