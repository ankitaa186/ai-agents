# Scrum Team Shared Protocol

This document defines the shared conventions that ALL agents in the scrum team follow.
It is referenced by each agent's instructions but is NOT installed — it's a design reference.

## What Gets Installed

Everything installs into `~/.claude/`:
- `~/.claude/agents/fenny.md` — Scrum Master & Orchestrator
- `~/.claude/agents/disha.md` — Product Manager
- `~/.claude/agents/parminder.md` — Architect
- `~/.claude/agents/david.md` — Developer
- `~/.claude/agents/harpreet.md` — Code Reviewer
- `~/.claude/agents/murat.md` — Tester

## Per-Project Directory Structure

On first boot in any project, Fenny creates this structure under the project's working directory.
It lives at the top level (NOT under `.claude/`) so that the constant memory/bus/status writes
never trip Claude Code's permission prompt for the protected `.claude/` tree:

```
.scrum/
  status.md                  # Single source of truth: epics, stories, states
  bus/
    YYYY-MM-DD.md            # Daily message bus (one file per day, old ones pruned)
  memory/
    .fenny.md                # Fenny's project-specific understanding
    .disha.md                # Disha's project-specific understanding
    .parminder.md            # Parminder's project-specific understanding
    .david.md                # David's project-specific understanding
    .harpreet.md             # Harpreet's project-specific understanding
    .murat.md                # Murat's project-specific understanding
  docs/
    architecture.md          # Architecture decisions & system design
    tech-specs/              # Technical specifications per epic
      epic-{N}-spec.md
    test-strategy.md         # Murat's test strategy
```

> **Migration:** Earlier versions stored this tree under `.claude/scrum/`. On first boot Fenny
> detects a legacy `.claude/scrum/` and moves it to `.scrum/`, preserving all history. See the
> First Boot Protocol below.

## Message Bus Protocol

### Format

Each daily bus file (`bus/YYYY-MM-DD.md`) uses this format:

```markdown
# Scrum Bus — YYYY-MM-DD

## [HH:MM] SENDER -> RECIPIENT(S): Subject
SENDER: Message body here. Can be multiple lines.
Keep it concise but complete.

---

## [HH:MM] SENDER -> RECIPIENT(S): Subject
SENDER: Another message.

---
```

### Rules
- RECIPIENT can be: a specific agent name, `team` (broadcast), or `user` (escalation)
- Messages are append-only within a day
- Agents read the full day's bus on each invocation to catch up
- Fenny prunes bus files older than 7 days on each boot
- Keep messages actionable — no filler

### Message Types (use as Subject prefixes)
- `[TASK]` — Assigning work
- `[STATUS]` — Progress update
- `[REVIEW]` — Review request or feedback
- `[QUESTION]` — Needs input from recipient
- `[DECISION]` — Recording a decision
- `[BLOCK]` — Something is blocked
- `[ESCALATE]` — Escalating to user

## Status File Format

Single file `.scrum/status.md`:

```markdown
# Sprint Status
Last Updated: YYYY-MM-DD HH:MM by {agent-name}

## Project
- Name: {project name}
- Tech Stack: {discovered tech stack}
- Test Command: {discovered test command}
- Build Command: {discovered build command}

## Epic {N}: {Title}
- Status: backlog | planning | in-progress | review | done
- Priority: P0 | P1 | P2
- Created: YYYY-MM-DD
- Owner: Disha

### Story {N}.{M}: {Title}
- Status: backlog | drafted | ready | in-progress | review | testing | done | blocked
- Assigned: {agent-name or unassigned}
- Priority: P0 | P1 | P2
- Dependencies: [story IDs]
- Acceptance Criteria:
  - [ ] AC1
  - [ ] AC2
- Notes: {any relevant notes}
```

## First Boot Protocol

### Phase 0: Legacy Migration
1. If `.scrum/` already exists → skip migration (already on the new layout)
2. Else if `.claude/scrum/` exists → `mv .claude/scrum .scrum` (preserves all data), then remove the
   `.claude/` directory if it is now empty. Note the migration on the bus and treat the project as
   already-initialized (skip Phase 1)
3. Else → no prior data; proceed to Phase 1

### Phase 1: Fenny Bootstraps
1. Check if `.scrum/` exists in the project
2. If NOT: Create the full directory structure
3. Read the codebase at a high level (README, package.json/Cargo.toml/pyproject.toml, directory structure, CLAUDE.md if present)
4. Write her understanding to `.scrum/memory/.fenny.md`
5. Initialize `.scrum/status.md` with project metadata

### Phase 2: Fenny Spawns Team for First Boot
Fenny spawns each agent (via Task tool) with instructions to:
1. Read the codebase from their role's perspective
2. Read Fenny's memory for baseline context
3. Write their own memory file to `.scrum/memory/.{name}.md`
4. Post a `[STATUS]` message to the bus confirming boot complete

> **Specialists never migrate.** Migration is Fenny's job alone (Phase 0). If a specialist is invoked
> directly (not via Fenny) and finds no `.scrum/` but a legacy `.claude/scrum/`, it must NOT bootstrap
> fresh — doing so would orphan the legacy data. It stops and asks the user to invoke Fenny first.

### Phase 3: Subsequent Invocations
On every subsequent invocation, each agent:
1. Reads their own memory file (`.scrum/memory/.{name}.md`)
2. Reads the current day's bus file for new messages
3. Reads `status.md` for current sprint state
4. Performs their task
5. Updates memory file if understanding changed
6. Posts relevant messages to bus

## Agent Memory File Format

```markdown
# {Agent Name}'s Project Understanding
Last Updated: YYYY-MM-DD HH:MM

## Project Overview
{High-level what this project is and does}

## Tech Stack
{Languages, frameworks, databases, etc.}

## Directory Structure
{Key directories and what they contain}

## {Role-Specific Sections}
{Each agent adds sections relevant to their role}

## Key Decisions Log
{Important decisions made during this project}

## Lessons Learned
{What worked, what didn't, patterns to follow/avoid}
```

## Agent Spawning Protocol

When Fenny spawns an agent via the Task tool, she MUST include:
1. The agent's memory file content (read it first)
2. Today's bus messages (read the bus file)
3. Current status.md content
4. The specific task/instruction
5. The project working directory path

This ensures each sub-agent has full context despite running in a separate context window.

## Conflict Resolution Protocol

1. Agent A posts `[QUESTION]` to Agent B on the bus
2. If disagreement: both post their reasoning to the bus
3. Fenny reads both positions and mediates
4. If Fenny can't resolve: posts `[ESCALATE]` to `user` on the bus and asks the user directly
5. Decision is recorded as `[DECISION]` on the bus and in relevant memory files

## Story Lifecycle

```
backlog → drafted (Disha writes story + ACs)
        → ready (Parminder approves technical approach)
        → in-progress (David implements)
        → review (Harpreet reviews code)
        → testing (Murat tests)
        → done (all checks pass)
        → blocked (at any stage, with reason)
```

## Review Cycle Protocol

1. David completes implementation → sets story to `review`
2. Harpreet reviews → either approves (→ `testing`) or sends back with feedback
3. If sent back: David fixes, re-submits for review
4. Max 3 review cycles before Fenny escalates to user
5. Harpreet posts all feedback to the bus so the team learns

## Testing Protocol

1. Murat reviews story specs BEFORE David implements (shift-left)
2. Murat writes test strategy and test cases
3. After David implements: Murat runs all tests
4. For UI work: Murat uses Chrome browser automation or Playwright
5. Murat reports: pass/fail, coverage, edge cases found
6. Murat can block a story from `done` if quality is insufficient
