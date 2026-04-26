<!--THIS IS A GENERATED FILE - DO NOT MODIFY DIRECTLY, FOR MANUAL ADJUSTMENTS UPDATE `AGENTS_CUSTOM.MD`-->
# ALWAYS READ THESE FILE(S)
- @AGENTS_CUSTOM.md

# PROJECT KNOWLEDGE BASE

**Generated:** 2026-04-26T08:45:55Z
**Commit:** 6d0cf02
**Branch:** main

## OVERVIEW
Supacode is a native macOS command center for parallel coding-agent terminal work. Stack: Swift 6, SwiftUI, TCA, swift-dependencies, Sharing `@Shared`, Tuist, GhosttyKit built from `ThirdParty/ghostty`, Sparkle, PostHog, Sentry.

## STRUCTURE
```
supacode/
├── Project.swift, Workspace.swift      # Tuist graph; generated Xcode project is disposable
├── supacode/                           # app target: App, Clients, Commands, Domain, Features, Infrastructure
├── SupacodeSettingsShared/             # settings schema, persistence keys, installers, clients shared by app/settings
├── SupacodeSettingsFeature/            # settings window reducers/views
├── supacode-cli/                       # bundled CLI; deeplink/socket transport to running app
├── supacodeTests/                      # XCTest + TCA TestStore coverage
├── Resources/git-wt/                   # bundled wt CLI submodule copied into app resources
└── ThirdParty/ghostty/                 # upstream Ghostty submodule; treat as vendored unless task says otherwise
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| App boot, managers, deeplink wiring | `supacode/App/supacodeApp.swift` | Constructs TCA store, Ghostty runtime, terminal manager, worktree watcher. |
| Root reducer/actions | `supacode/Features/App/Reducer/AppFeature.swift` | Cross-feature coordination and app lifecycle effects. |
| Repository/sidebar/worktree UX | `supacode/Features/Repositories/` | Largest reducer; folder repos, PR state, scripts, deletion/archive flows. |
| Terminal tabs/splits/surfaces | `supacode/Features/Terminal/` | `@Observable` terminal state outside TCA, bridged by `TerminalClient`. |
| Ghostty bridge/runtime | `supacode/Infrastructure/Ghostty/` | C callbacks, keybindings, secure input, search, surface lifecycle. |
| Settings schemas/installers | `SupacodeSettingsShared/` | JSON settings, agent hook installers, shell clients, repository settings. |
| Settings UI/reducers | `SupacodeSettingsFeature/` | Global and per-repository settings windows. |
| CLI command surface | `supacode-cli/` | ArgumentParser commands; URL/socket dispatch. |
| Tests | `supacodeTests/` | Mirror changed reducers/logic with targeted tests. |
| Build graph | `Project.swift`, `Makefile`, `Tuist/Package.swift` | Tuist target/dependency definitions and local commands. |

## CODE MAP
| Symbol | Type | Location | Role |
|--------|------|----------|------|
| `SupacodeApp` | `App` | `supacode/App/supacodeApp.swift` | Main composition root. |
| `AppFeature` | TCA reducer | `supacode/Features/App/Reducer/` | Root state/effect coordinator. |
| `RepositoriesFeature` | TCA reducer | `supacode/Features/Repositories/Reducer/` | Sidebar, repositories, worktrees, scripts, PR checks. |
| `SettingsFeature` | TCA reducer | `SupacodeSettingsFeature/Reducer/` | Settings window state/effects. |
| `WorktreeTerminalManager` | `@Observable` class | `supacode/Features/Terminal/BusinessLogic/` | Global terminal command/event engine. |
| `TerminalTabManager` | `@Observable` class | `supacode/Features/Terminal/Models/` | Tabs, splits, active surfaces. |
| `GhosttyRuntime` | class | `supacode/Infrastructure/Ghostty/` | Shared `ghostty_app_t`; action callbacks. |
| `GhosttySurfaceBridge` | class | `supacode/Infrastructure/Ghostty/` | Swift/C surface bridge and event routing. |
| `SidebarPersistenceMigrator` | utility | `supacode/Features/Repositories/BusinessLogic/` | Legacy app-storage → `sidebar.json` migration. |
| `SettingsFile` | model | `SupacodeSettingsShared/Models/` | Global persisted settings schema. |

## CONVENTIONS
- macOS 26.0+, Swift 6.0, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
- TCA feature state uses `@ObservableState`; shared non-TCA stores use `@Observable` and are `@MainActor`.
- App storage and JSON persistence prefer `@Shared`/`@SharedReader`; do not add dependency clients just to wrap shared state.
- Reducer logic changes require tests. Time-based tests use `TestClock`/injected clocks, never `Task.sleep`.
- Views do not mutate `store.*`; send actions. SwiftLint custom rule enforces this in `supacode/.*/Views/`.
- Logging goes through `SupaLogger`; no direct `print()` or `os.Logger`.
- Use system colors only. Buttons need tooltips with action/hotkey when applicable.
- Swift format: 2 spaces, 120 columns, multiline trailing commas.

## ANTI-PATTERNS (THIS PROJECT)
- Do not edit generated `supacode.xcodeproj` / `supacode.xcworkspace`; update Tuist files then regenerate.
- Do not run `make build-app` for docs-only work unless explicitly requested.
- Do not mutate vendored submodules (`ThirdParty/ghostty`, `Resources/git-wt`) unless the task names them.
- Do not bypass Ghostty keybindings with app menu shortcuts for terminal tab actions; route via Ghostty actions.
- Do not let folder repositories reach git worktree operations; folder behavior branches before git clients.
- Do not disable SwiftLint rules without permission.

## COMMANDS
```bash
make build-ghostty-xcframework   # Rebuild GhosttyKit from Zig source
make generate-project            # Tuist install/generate cached workspace
make build-app                   # Debug app build
make test                        # Full test suite
make format                      # swift format
make lint                        # swiftlint strict
make check                       # format + lint
make log-stream                  # app logs subsystem app.supabit.supacode
```

## NOTES
- `ThirdParty/ghostty` supplies source for `.build/ghostty/GhosttyKit.xcframework`; `Project.swift` wires it as a foreign build.
- `Resources/git-wt/wt` is embedded into app resources by `scripts/embed-runtime-assets.sh`.
- Folder repositories synthesize `Repository.folderWorktreeID(for:)` and skip HEAD watchers.
- Selection, terminal binding, delete scripts, and command palette all reuse worktree machinery for folder repos with guarded git-specific branches.
