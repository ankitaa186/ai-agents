# CLAUDE.md

## Project Overview

This is an AI scrum team implemented as 6 Claude Code agent files (pure Markdown).
There is no application code — the entire project is prompt engineering in `.md` files.

Agents are installed to `~/.claude/agents/` via `install.sh` and become available
in any project through Claude Code's `/agents` command. At runtime, agents communicate
through a file-based message bus at `.scrum/bus/` under the target project.

### The Team

| Agent | File | Role |
|-------|------|------|
| John | `agents/john.md` | Scrum Master & Orchestrator |
| Penny | `agents/penny.md` | Product Manager |
| Aria | `agents/aria.md` | Architect |
| Dev | `agents/dev.md` | Developer |
| Remy | `agents/remy.md` | Code Reviewer |
| Tess | `agents/tess.md` | Tester |

## File Structure

- `agents/` — Agent definition files (the core deliverable)
- `install.sh` — Installs/updates/uninstalls agents to `~/.claude/agents/`
- `PROTOCOL.md` — Shared protocol design reference (not installed, not read at runtime)
- `README.md`, `CONTRIBUTING.md`, `LICENSE`, `CHANGELOG.md`, `MIGRATION.md` — Project docs

## Key Conventions

- Agent files use Claude Code agent frontmatter (`name`, `description`, `model`, `color`). Each agent's per-project memory is a runtime file at `.scrum/memory/.{name}.md` that the agent reads itself — it is not declared in frontmatter.
- Agents are **project-agnostic** — they discover everything from the codebase they run in.
  Never hardcode project-specific paths, languages, or conventions.
- Agents are **self-contained** — each file must work standalone without referencing
  other files at runtime. PROTOCOL.md is a design reference only; its content is
  inlined into each agent during authoring.
- Agent descriptions must include `<example>` blocks so Claude Code can auto-route
  user messages to the correct agent.
- Per-project runtime data lives in a top-level `.scrum/` directory under the target project
  (status.md, bus/, memory/, docs/). It deliberately sits OUTSIDE `.claude/` — writes inside the
  protected `.claude/` tree trigger a permission prompt on every operation, and these agents write
  constantly. Earlier versions used `.claude/scrum/`; John auto-migrates that on first boot.

## How to Test Changes

1. Run `./install.sh` to install agents to `~/.claude/agents/`.
2. Open Claude Code in any project directory.
3. Invoke an agent (e.g., `/agents` then select John) and verify behavior.
4. Check that `.scrum/` structures are created correctly in the target project.

For uninstall: `./install.sh --uninstall`

## Important Rules

- **Never break self-containment.** Each agent must work as a standalone file
  with no runtime dependencies on other files in this repo.
- **Never hardcode project specifics.** Agents must work in any codebase.
- **Maintain backward compatibility** with existing runtime data in user projects. The bus format
  and `.scrum/` directory structure are a contract — changing them is a breaking change. The one
  sanctioned relocation (`.claude/scrum/` → `.scrum/`) is handled by John's first-boot migration so
  no existing data is lost.
- **Keep agent descriptions accurate.** The `<example>` blocks in frontmatter
  drive auto-routing — incorrect examples cause mis-routing.
- **PROTOCOL.md is the source of truth** for shared conventions. When updating
  protocol, propagate changes into each affected agent file manually.

## Build & Lint

There is no build step. To validate:
- Ensure all 6 agent files exist in `agents/` and have valid YAML frontmatter.
- Ensure `install.sh` runs cleanly: `bash -n install.sh` (syntax check).
- Ensure no agent file references external files with runtime read operations.
