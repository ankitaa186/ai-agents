# Scrum Team Shared Protocol

This document defines the shared conventions that ALL agents in the scrum team follow.
It is referenced by each agent's instructions but is NOT installed — it's a design reference.

## What Gets Installed

Everything installs into `~/.claude/`:
- `~/.claude/agents/john.md` — Scrum Master & Orchestrator
- `~/.claude/agents/penny.md` — Product Manager
- `~/.claude/agents/aria.md` — Architect
- `~/.claude/agents/dave.md` — Developer
- `~/.claude/agents/remy.md` — Code Reviewer
- `~/.claude/agents/tess.md` — Tester

## Per-Project Directory Structure

On first boot in any project, John creates this structure under the project's working directory.
It lives at the top level (NOT under `.claude/`) so that the constant memory/bus/status writes
never trip Claude Code's permission prompt for the protected `.claude/` tree:

```
.scrum/
  status.md                  # Single source of truth: epics, stories, states
  bus/
    YYYY-MM-DD.md            # Daily message bus (one file per day, old ones pruned)
  memory/
    .john.md                # John's project-specific understanding
    .penny.md                # Penny's project-specific understanding
    .aria.md            # Aria's project-specific understanding
    .dave.md                # Dave's project-specific understanding
    .remy.md             # Remy's project-specific understanding
    .tess.md                # Tess's project-specific understanding
  docs/
    architecture.md          # Architecture decisions & system design
    tech-specs/              # Technical specifications per epic
      epic-{N}-spec.md
    test-strategy.md         # Tess's test strategy
```

> **Migration:** Earlier versions stored this tree under `.claude/scrum/`, and named the team
> Fenny/Disha/Parminder/David/Harpreet/Murat. On first boot John detects a legacy `.claude/scrum/`
> and moves it to `.scrum/`, and renames any old-named `.scrum/memory/.{old-name}.md` files to the
> current names — preserving all history. See the First Boot Protocol below.

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
- John prunes bus files older than 7 days on each boot
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
- Owner: Penny

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

**0a — Directory relocation.**
1. If `.scrum/` already exists → skip 0a (already on the new layout)
2. Else if `.claude/scrum/` exists → `mv .claude/scrum .scrum` (preserves all data), then remove the
   `.claude/` directory if it is now empty. Note the migration on the bus and treat the project as
   already-initialized (skip Phase 1)
3. Else → no prior data; proceed to Phase 1

**0b — Agent-name relocation.** The team was renamed in two waves — the original
Fenny/Disha/Parminder/David/Harpreet/Murat to neutral names, then the Developer from Dev to Dave — and is
now John/Penny/Aria/Dave/Remy/Tess. For each rename, move the old memory file to the new name when the old
exists and the new does not (`.fenny.md`→`.john.md`, `.disha.md`→`.penny.md`, `.parminder.md`→`.aria.md`,
`.david.md`→`.dave.md`, `.dev.md`→`.dave.md`, `.harpreet.md`→`.remy.md`, `.murat.md`→`.tess.md`) and note
the migration on the bus. Idempotent; runs on every boot, not just first boot.

### Phase 1: John Bootstraps
1. Check if `.scrum/` exists in the project
2. If NOT: Create the full directory structure
3. Read the codebase at a high level (README, package.json/Cargo.toml/pyproject.toml, directory structure, CLAUDE.md if present)
4. Write his understanding to `.scrum/memory/.john.md`
5. Initialize `.scrum/status.md` with project metadata

### Phase 2: John Spawns Team for First Boot
John spawns each agent (via Task tool) with instructions to:
1. Read the codebase from their role's perspective
2. Read John's memory for baseline context
3. Write their own memory file to `.scrum/memory/.{name}.md`
4. Post a `[STATUS]` message to the bus confirming boot complete

> **Specialists never migrate.** Migration is John's job alone (Phase 0). If a specialist is invoked
> directly (not via John) and finds either legacy layout — no `.scrum/` but a legacy `.claude/scrum/`, or
> a `.scrum/` whose memory files still use the old agent names — it must NOT bootstrap fresh, since that
> would orphan the legacy data. It stops and asks the user to invoke John first.

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

When John spawns an agent via the Task tool, he MUST include:
1. The agent's memory file content (read it first)
2. Today's bus messages (read the bus file)
3. Current status.md content
4. The specific task/instruction
5. The project working directory path

This ensures each sub-agent has full context despite running in a separate context window.

## Conflict Resolution Protocol

1. Agent A posts `[QUESTION]` to Agent B on the bus
2. If disagreement: both post their reasoning to the bus
3. John reads both positions and mediates
4. If John can't resolve: posts `[ESCALATE]` to `user` on the bus and asks the user directly
5. Decision is recorded as `[DECISION]` on the bus and in relevant memory files

## Story Lifecycle

```
backlog → drafted (Penny writes story + ACs)
        → ready (Aria approves technical approach)
        → in-progress (Dave implements)
        → review (Remy reviews code)
        → testing (Tess tests)
        → done (all checks pass)
        → blocked (at any stage, with reason)
```

## Review Cycle Protocol

1. Dave completes implementation → sets story to `review`
2. Remy reviews → either approves (→ `testing`) or sends back with feedback
3. If sent back: Dave fixes, re-submits for review
4. Max 3 review cycles before John escalates to user
5. Remy posts all feedback to the bus so the team learns

## Testing Protocol

1. Tess reviews story specs BEFORE Dave implements (shift-left)
2. Tess writes test strategy and test cases
3. After Dave implements: Tess runs all tests
4. For UI work: Tess uses Chrome browser automation or Playwright
5. Tess reports: pass/fail, coverage, edge cases found
6. Tess can block a story from `done` if quality is insufficient
