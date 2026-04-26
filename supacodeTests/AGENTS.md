<!--THIS IS A GENERATED FILE - DO NOT MODIFY DIRECTLY, FOR MANUAL ADJUSTMENTS UPDATE `AGENTS_CUSTOM.MD`-->
# PROJECT KNOWLEDGE BASE: `supacodeTests/`

## OVERVIEW
XCTest suite for reducers, dependency clients, terminal state, settings persistence/installers, CLI hooks, Git/GitHub parsing, folder repositories, and layout/sidebar behavior.

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| App reducer tests | `AppFeature*Tests.swift` | Lifecycle, deeplinks, settings, terminal setup. |
| Repositories tests | `RepositoriesFeature*Tests.swift`, `Repository*Tests.swift`, `Sidebar*Tests.swift` | Sidebar/worktree/repo logic. |
| Terminal tests | `Terminal*Tests.swift`, `Ghostty*Tests.swift`, `WorktreeTerminalManagerTests.swift` | Tabs, splits, surface bridge, rendering policy. |
| Settings/agents | `Settings*Tests.swift`, `*InstallerTests.swift`, `AgentHook*Tests.swift` | JSON persistence and hook installation. |
| Test helpers | `RepositoriesFeature+TestHelpers.swift`, `SettingsTestStorage.swift` | Shared fixtures/storage. |

## CONVENTIONS
- Reducer tests use TCA `TestStore` and exhaust received actions.
- Time uses `TestClock` or injected clock dependencies; never `Task.sleep`.
- File-persistence tests use temporary/test storage, not user real settings files.
- Add focused tests next to the feature changed; one bug fix should prove the bug first.

## ANTI-PATTERNS
- Do not run full `make test` when a targeted XCTest is enough during iteration.
- Do not assert on nondeterministic ordering unless the feature guarantees it.
- Do not touch live `~/Library/Application Support` settings in tests.
