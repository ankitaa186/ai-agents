# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2026-06-19

### Changed

- **Renamed the Developer agent from Dev to Dave.** "Dev" collided with the generic word for the role
  it plays — "put a dev on it" could mean the agent *or* any developer — so the proper noun kept
  dissolving into the common noun. "Dave" is a plain name with no such ambiguity (and a near-rhyme of
  the old one). The agent file moved to `agents/dave.md`, the `subagent_type` is now `dave`, and
  per-project memory is keyed by `.scrum/memory/.dave.md`. The other five agents are unchanged.

### Migration

- `install.sh` now also removes a stale `dev.md` from `~/.claude/agents/` on install/uninstall, and
  migrates `.scrum/memory/.dev.md` → `.dave.md` (alongside the original `.david.md` → `.dave.md`).
- John auto-migrates `.dev.md` → `.dave.md` on boot, so projects on v0.3.x move over with no manual
  steps. The `.scrum/` data format is unchanged — no history is lost. See [MIGRATION.md](MIGRATION.md).

## [0.3.0] - 2026-06-19

### Changed

- **Renamed the six agents from real-person names to neutral names.** The team is now
  John (Scrum Master/Orchestrator), Penny (Product Manager), Aria (Architect), Dev (Developer),
  Remy (Code Reviewer), and Tess (Tester) — previously Fenny, Disha, Parminder, David, Harpreet,
  and Murat respectively. Agent filenames moved to match (`agents/john.md`, …), and per-project
  memory files are now keyed by the new names (`.scrum/memory/.john.md`, …).

### Added

- `install.sh` now removes the legacy `fenny.md`/`disha.md`/`parminder.md`/`david.md`/`harpreet.md`/`murat.md`
  files from `~/.claude/agents/` on install (and uninstall), so a re-install replaces the old team cleanly
  instead of leaving stale duplicates behind.
- `install.sh` migrates the `.scrum/` memory of the project it is run from, renaming old-named memory files
  to the new agent names as part of a normal install.
- John auto-migrates legacy per-project memory on boot: old-named `.scrum/memory/.{old-name}.md` files are
  renamed to the new names, preserving each agent's accumulated project memory. No manual migration needed.
- Specialist first-boot guards now also detect the pre-rename layout (old-named memory present, new absent)
  and defer to John for migration rather than bootstrapping fresh and orphaning history.
- `MIGRATION.md` with step-by-step upgrade instructions for existing installs.

### Migration

See [MIGRATION.md](MIGRATION.md). In short: `git pull`, run `./install.sh`, then invoke `john` once in
each project that used the team — John renames the memory files automatically. The `.scrum/` data format is
unchanged, so no history is lost.

## [0.2.0] - 2026-05-31

### Changed

- **Moved per-project runtime data from `.claude/scrum/` to a top-level `.scrum/` directory.**
  The old location lived inside Claude Code's protected `.claude/` tree, so every memory, bus, and
  status write triggered a permission prompt — and these agents write constantly. The new top-level
  `.scrum/` directory is outside that tree, eliminating the repeated prompts.

### Added

- Fenny auto-migrates a legacy `.claude/scrum/` directory to `.scrum/` on first boot, preserving all
  status, bus history, memory, and docs. No manual migration needed.
- First-boot guard in every specialist agent: if invoked directly (not via Fenny) on a project that
  still has only the legacy `.claude/scrum/`, the agent stops and asks the user to run Fenny first
  rather than bootstrapping fresh `.scrum/` state and orphaning the existing history.

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
