<!--THIS IS A GENERATED FILE - DO NOT MODIFY DIRECTLY, FOR MANUAL ADJUSTMENTS UPDATE `AGENTS_CUSTOM.MD`-->
# PROJECT KNOWLEDGE BASE: `supacode/Features/Repositories/`

## OVERVIEW
Sidebar/repository/worktree feature. Owns repo list state, folder repo handling, worktree creation/removal/archive, PR/check UI, script actions, and sidebar persistence migration.

## STRUCTURE
```
Repositories/
├── Reducer/         # `RepositoriesFeature`, removal/customization/prompt child reducers
├── BusinessLogic/   # sidebar persistence, colors, worktree info watcher
├── Models/          # toolbar notification grouping
└── Views/           # sidebar rows, popovers, details, worktree prompt
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Main reducer | `Reducer/RepositoriesFeature.swift` | Large file; search action case first. |
| Removal flow | `Reducer/RepositoriesFeature+Removal.swift` | Delete/archive branching and batch completion. |
| Sidebar persistence | `BusinessLogic/SidebarPersistenceKey.swift`, `SidebarPersistenceMigrator.swift` | `@Shared(.sidebar)` and legacy migration. |
| Worktree watcher | `BusinessLogic/WorktreeInfoWatcherManager.swift` | HEAD/file/PR refresh events. |
| Sidebar list rendering | `Views/SidebarItemsView.swift`, `SidebarItemView.swift`, `SidebarListView.swift` | Custom rule blocks direct `store.*` mutation. |
| Worktree detail | `Views/WorktreeDetailView.swift` | Terminal/detail actions and settings links. |

## CONVENTIONS
- Folder repositories are first-class but non-git: one synthesized worktree, no pin/archive/new-worktree, no HEAD watcher.
- Delete script flow branches inside existing removal pipeline; `removingRepositoryIDs` preserves folder intent.
- Repository settings use `@Shared(.repositorySettings(rootURL))`; global settings use `@Shared(.settingsFile)`.
- PR refresh combines GitHub CLI/integration clients with watcher events; keep async effects cancellable.

## ANTI-PATTERNS
- Do not call `gitClient.removeWorktree` for folder repositories.
- Do not mutate `store` from views; send a view action.
- Do not assume section headers exist for folder repositories.
