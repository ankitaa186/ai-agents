# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-05-31

### Changed

- **Moved per-project runtime data from `.claude/scrum/` to a top-level `.scrum/` directory.**
  The old location lived inside Claude Code's protected `.claude/` tree, so every memory, bus, and
  status write triggered a permission prompt — and these agents write constantly. The new top-level
  `.scrum/` directory is outside that tree, eliminating the repeated prompts.

### Added

- Fenny auto-migrates a legacy `.claude/scrum/` directory to `.scrum/` on first boot, preserving all
  status, bus history, memory, and docs. No manual migration needed.

## [0.1.0] - 2026-04-15

Initial release -- 6 agent scrum team.

### Added

- Fenny -- Scrum Master & Orchestrator agent
- Disha -- Product Manager agent
- Parminder -- Architect agent
- David -- Developer agent
- Harpreet -- Code Reviewer agent
- Murat -- Tester agent
- Shared protocol defining agent communication conventions
- Per-project runtime structure under `.claude/scrum/`
- Installation to `~/.claude/agents/` via file copy
