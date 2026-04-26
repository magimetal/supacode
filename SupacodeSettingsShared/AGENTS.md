<!--THIS IS A GENERATED FILE - DO NOT MODIFY DIRECTLY, FOR MANUAL ADJUSTMENTS UPDATE `AGENTS_CUSTOM.MD`-->
# PROJECT KNOWLEDGE BASE: `SupacodeSettingsShared/`

## OVERVIEW
Shared settings/domain package for app and settings UI. Owns persisted JSON schemas, `@Shared` keys, coding-agent installers, shell/git helpers, analytics/notification clients, shortcuts, and support utilities.

## STRUCTURE
```
SupacodeSettingsShared/
├── App/             # app shortcuts and keyboard display helpers
├── BusinessLogic/   # settings persistence, agent hooks, CLI/skill installers
├── Clients/         # analytics, coding-agent settings, shell, notifications, repo settings git
├── Domain/          # action policies and open-worktree action models
├── Models/          # `SettingsFile`, repo settings, scripts, hooks, colors
└── Support/         # paths, logger, small UI support
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Global schema | `Models/SettingsFile.swift` | Canonical settings JSON model. |
| Repo settings | `Models/RepositorySettings.swift`, `BusinessLogic/RepositorySettingsKey.swift` | Merged global/local repository settings. |
| Settings file IO | `BusinessLogic/SettingsFilePersistence.swift` | URL/storage dependency keys. |
| Agent hooks | `BusinessLogic/*Hook*`, `Models/AgentHooksInstallState.swift` | Claude/Codex/Kiro/Pi hook install logic. |
| CLI install/skills | `BusinessLogic/CLIInstaller.swift`, `CLISkillInstaller.swift`, `CLISkillContent.swift` | Bundled CLI and skill content. |
| Shell execution | `Clients/Shell/*` | Async shell stream/result abstractions. |

## CONVENTIONS
- Keep settings models Codable and migration-tolerant.
- Use `@Shared(.settingsFile)` and `@Shared(.repositorySettings(rootURL))` instead of ad-hoc file reads.
- Shell clients return structured output/errors; reducers consume dependencies, not `Process` directly.
- Agent-specific installers should preserve unrelated user settings.

## ANTI-PATTERNS
- Do not put app-only UI state in shared settings models.
- Do not hardcode user paths; route through `SupacodePaths` / dependency keys.
- Do not overwrite whole third-party agent config files when merging hook entries.
