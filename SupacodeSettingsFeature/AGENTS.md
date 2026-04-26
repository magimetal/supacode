<!--THIS IS A GENERATED FILE - DO NOT MODIFY DIRECTLY, FOR MANUAL ADJUSTMENTS UPDATE `AGENTS_CUSTOM.MD`-->
# PROJECT KNOWLEDGE BASE: `SupacodeSettingsFeature/`

## OVERVIEW
Settings window package. TCA reducers and SwiftUI views for appearance, notifications, coding agents, shortcuts, GitHub, worktree defaults, and per-repository scripts/settings.

## STRUCTURE
```
SupacodeSettingsFeature/
├── Reducer/   # `SettingsFeature`, `RepositorySettingsFeature`
├── Models/    # summary models passed into settings UI
└── Views/     # settings panes and reusable section/card views
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Global settings reducer | `Reducer/SettingsFeature.swift` | Agent installers, archived dates bridge, analytics. |
| Repository settings reducer | `Reducer/RepositorySettingsFeature.swift` | Per-repo scripts/settings with git branch queries. |
| Main settings view | `Views/SettingsView.swift` | Pane composition. |
| Repo/worktree panes | `Views/RepositorySettingsView.swift`, `WorktreeSettingsView.swift`, `RepositoryScriptsSettingsView.swift` | Folder-specific hidden sections are decided upstream. |
| Hotkeys | `Views/KeyboardShortcutsSettingsView.swift`, `HotkeyRecorderView.swift` | Shortcut override UI. |

## CONVENTIONS
- Read/write global settings through `@Shared(.settingsFile)`.
- Per-repository edits use `@Shared(.repositorySettings(rootURL))` and shared clients from `SupacodeSettingsShared`.
- Keep views layout-agnostic; parent controls placement.

## ANTI-PATTERNS
- Do not duplicate settings schemas in this package.
- Do not directly probe filesystem/Git from views; use reducer dependencies.
- Do not show setup/archive script controls for folder repositories.
