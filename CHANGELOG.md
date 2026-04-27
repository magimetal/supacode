# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.9.2] - 2026-04-27

### Fixed

- Exclude generated agent instruction docs from app buildable folders to prevent duplicate bundled `AGENTS.md` / `CLAUDE.md` resources.

## [0.9.1] - 2026-04-27

### Added

- Add generated hierarchical `AGENTS.md` project documentation and `CLAUDE.md` compatibility links for agent guidance.

### Changed

- Update repository agent guidance and ignore generated `.trash/` artifacts.

### Fixed

- Fix browser pane hover hit-testing stealing pane focus; browser panes now request focus only for mouse-down events.
