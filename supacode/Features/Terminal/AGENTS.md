<!--THIS IS A GENERATED FILE - DO NOT MODIFY DIRECTLY, FOR MANUAL ADJUSTMENTS UPDATE `AGENTS_CUSTOM.MD`-->
# PROJECT KNOWLEDGE BASE: `supacode/Features/Terminal/`

## OVERVIEW
Terminal state, tabs, splits, notifications, search overlays, and Ghostty surface presentation. Runtime state is `@Observable`, bridged to reducers through `TerminalClient` events/commands.

## STRUCTURE
```
Terminal/
├── BusinessLogic/   # `WorktreeTerminalManager`, layout persistence
├── Models/          # tab/split/surface/worktree terminal state
├── TabBar/          # tab bar styling and views
└── Views/           # split tree, Ghostty overlays, terminal pane views
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Command/event engine | `BusinessLogic/WorktreeTerminalManager.swift` | Receives commands, emits events, saves layouts. |
| Per-worktree state | `Models/WorktreeTerminalState.swift` | Tabs, surfaces, notifications, blocking scripts. |
| Split tree | `Models/SplitTree.swift`, `Views/TerminalSplitTreeView.swift` | Split layout model + rendering. |
| Tab management | `Models/TerminalTabManager.swift`, `TabBar/Views/*` | Tabs, active tab, tab bar measurement. |
| Surface UI | `Views/WorktreeTerminalTabsView.swift`, `Views/GhosttySurface*` | Host Ghostty bridge views and overlays. |

## CONVENTIONS
- `WorktreeTerminalManager` is the single global terminal authority.
- Reducers communicate via `TerminalClient.send(Command)` and async event streams.
- Layouts persist through `@Shared(.layouts)` and repository/worktree IDs.
- Search/notifications are tied to active surface and selected worktree.

## ANTI-PATTERNS
- Do not store Ghostty surface runtime objects directly in TCA state.
- Do not use `Task.sleep` in terminal tests; inject/advance clocks.
- Do not duplicate tab keybinding logic outside Ghostty action callbacks.
