# AI Agents

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Claude Code](https://img.shields.io/badge/Built_for-Claude_Code-blueviolet)](https://claude.ai/claude-code)
[![Agents](https://img.shields.io/badge/Agents-6-green)]()

**A complete AI-powered scrum team, built as Claude Code agents.**

Six specialized agents collaborate to plan, architect, implement, review, and test
software projects autonomously. They are pure skill files (`.md`) that install to
`~/.claude/agents/` and work on ANY project -- no framework, no runtime, no dependencies.

You talk to one agent — **John**, the scrum master. He plans the work, pulls in the right
specialists, and they keep each other honest.

**When something breaks, they find the root cause — not just the symptom:**

```
Ankit: Annie spiraled last night — something let her act as the wrong user.
     Strip user_id from the tool schemas everywhere, and prove the server
     still injects it.

John (Scrum Master): Security boundary, not a quick patch — I'm not letting
     Dev near it until Aria signs off on where the strip belongs.

Aria (Architect): Strip it in the server's tool-list handler, NOT the client
     — the autonomous path proxies the server directly and bypasses the
     client. Both doors converge there; recipient IDs (person_id) stay
     untouched. The real bug: "user_id" is duplicated across the injector,
     the stripper, and 17 tool schemas — that silent drift is what caused
     the spiral. Extract one INJECTED_ACTOR_PARAM constant; key both sides
     off it. Rejecting the bigger per-tool refactor — over-engineering for
     a single injected param.

John: Clean. Dev — build exactly to Aria's conditions. Working tree only,
     run the suite, no commits.

Dev (Developer): Done. Stripped at the boundary, both paths verified,
     constant folded into the injector and stripper. 14 tests green;
     recipient routing unaffected.

Remy (Reviewer): Read the whole diff. The constant kills the drift class at
     the source, not just this one instance. Injection holds on every path.
     Approved.

John: Boundary closed, root cause gone, one-file blast radius. The diff's
     ready for your review.
```

**…and they'll stop you from over-building:**

```
Ankit: While you're in there, make the notifier pluggable — abstract it so we
     can drop in Slack or SMS later.

John (Scrum Master): That doesn't look like a good tangent, Ankit — we've got
     one notifier and nothing asking for a second. Let me check with Penny and
     Aria before we touch it.

Penny (PM): Nobody's asked for Slack or SMS. "Might be useful later" isn't a
     requirement — it's a guess we'd start paying interest on today.

Aria (Architect): And technically it's premature. A plugin layer for a single
     implementation is just indirection to maintain. One function, one config
     flag — when a real second channel shows up, we generalize then, in about
     an hour, because the call site stays clean.

John: Unanimous. We ship the simple version, and I'm parking "pluggable
     notifiers" — if a user actually asks, it becomes a real story with a spec.

Ankit: ...fine. Ship the simple one.
```

*Both are condensed from real sessions building a 200k-line production system — not scripted
demos (a few specifics simplified for readability). You bring the ideas; the team scopes them,
challenges them, builds them, and reviews them.*

---

## Table of Contents

- [The Team](#the-team)
- [How It Works](#how-it-works)
- [Architecture](#architecture)
- [Installation](#installation)
- [Usage](#usage)
- [Per-Project Structure](#per-project-structure)
- [Message Bus](#message-bus)
- [Memory System](#memory-system)
- [Story Lifecycle](#story-lifecycle)
- [Configuration](#configuration)
- [Contributing](#contributing)
- [License](#license)

---

## The Team

| Agent | Role | Color | Personality |
|-------|------|-------|-------------|
| **John** | Scrum Master & Orchestrator | `green` | Warm but efficient. Never writes code. Spawns and coordinates all agents. |
| **Penny** | Product Manager | `blue` | User-focused. Breaks goals into epics and stories with precise acceptance criteria. |
| **Aria** | Architect | `cyan` | Deep technical thinker. Owns system design, tech specs, and feasibility review. |
| **Dev** | Developer | `yellow` | Methodical implementer. Follows conventions, writes clean production code. |
| **Remy** | Code Reviewer | `red` | Quality gatekeeper. Thorough but fair. Will block bad code without hesitation. |
| **Tess** | Tester | `magenta` | Quality obsessive. Writes all test types. Performs live UI testing when needed. |

John is the only agent you need to invoke directly. He spawns the rest as
sub-agents via Claude Code's Task tool, passing each one full project context.

---

## How It Works

1. **You describe what you want.** Talk to John naturally -- a feature, a fix, an entire project.
2. **John spawns Penny** to write the epic and break it into stories with acceptance criteria.
3. **Aria reviews** each story for technical feasibility, writes a tech spec, and marks stories as "ready."
4. **Dev implements** ready stories, one at a time or in parallel when they touch different files.
5. **Remy reviews** Dev's code -- approves or rejects with specific, actionable feedback.
6. **Tess tests** approved stories against the acceptance criteria and edge cases.
7. **John tracks it all**, updates status, mediates conflicts, and reports progress to you.

Every action is logged on a shared message bus. Every agent maintains per-project
memory. Sprint state lives in a single status file. The entire system is resumable --
you can close your terminal, come back tomorrow, and John picks up exactly where
he left off.

---

## Architecture

```
                          +-----------+
                          |    You    |
                          +-----+-----+
                                |
                                v
                    +-----------+-----------+
                    |       John            |
                    |  (Scrum Master)       |
                    |  Orchestrates all     |
                    |  agents via Task tool |
                    +-+---+---+---+---+----+
                      |   |   |   |   |
          +-----------+   |   |   |   +------------+
          |               |   |   |                |
          v               v   |   v                v
    +----------+  +---------+ | +-----------+ +----------+
    |  Penny   |  |  Aria   | | |   Remy    | |   Tess   |
    |   (PM)   |  |  (Arch) | | | (Reviewer)| | (Tester) |
    +----------+  +---------+ | +-----------+ +----------+
                              v
                        +----------+
                        |   Dev    |
                        |  (Dev)   |
                        +----------+

    All agents read/write:
    ===================================================
    |              Message Bus                        |
    |  .scrum/bus/YYYY-MM-DD.md                       |
    ===================================================
    |              Status File                        |
    |  .scrum/status.md                               |
    ===================================================
    |              Per-Agent Memory                   |
    |  .scrum/memory/.{agent}.md                      |
    ===================================================
```

Key design decisions:

- **No server, no daemon.** Everything is file-based, living inside the project.
- **Stateless agents.** Each agent boots from files (memory + bus + status), does its
  work, writes results back. No long-running processes.
- **John is the single orchestrator.** He is the only agent that spawns others.
  This prevents race conditions and ensures coordinated workflow.
- **Append-only bus.** Messages are never edited or deleted within a day. Old daily
  files are pruned after 7 days.

---

## Installation

```bash
git clone https://github.com/ankitaa186/ai-agents.git
cd ai-agents
./install.sh
```

This copies the agent skill files to your Claude Code agents directory:

```
~/.claude/agents/
  john.md         # Scrum Master & Orchestrator
  penny.md        # Product Manager
  aria.md         # Architect
  dev.md          # Developer
  remy.md         # Code Reviewer
  tess.md         # Tester
```

To verify the installation:

```bash
ls ~/.claude/agents/
# Should list all six .md files
```

The agents are now available in any Claude Code session, in any project directory.

---

## Usage

### First Boot -- Initializing a New Project

Navigate to any project and invoke John:

```
> john, initialize the scrum team for this project
```

John will:
1. Create the `.scrum/` directory structure
2. Read your codebase to understand the project
3. Spawn all five agents in parallel for first-boot analysis
4. Report when everyone is ready

```
Scrum team initialized for my-web-app.
  Penny (PM): Ready -- identified 3 existing features and 5 product gaps
  Aria (Architect): Ready -- mapped architecture and tech debt
  Dev (Developer): Ready -- cataloged code patterns and build system
  Remy (Reviewer): Ready -- assessed code quality and standards
  Tess (Tester): Ready -- evaluated test coverage and frameworks

Awaiting your direction. What would you like us to build?
```

### Creating an Epic

```
> john, build a user authentication system with email/password login,
  registration, password reset, and session management
```

John spawns Penny, who drafts the epic and stories. Then Aria reviews for
technical feasibility. You get a plan to approve before any code is written.

### Running a Sprint

```
> john, start implementing the approved stories
```

John identifies dependency waves and begins spawning Dev for independent stories
in parallel. As each story completes, Remy reviews and Tess tests.

### Checking Status

```
> john, what's the sprint status?
```

```
Sprint Progress:

Epic 1: User Authentication [in-progress]
  Story 1.1: Set up auth database schema       [done]
  Story 1.2: Implement registration endpoint    [review -> Remy]  (cycle 1/3)
  Story 1.3: Implement login endpoint           [in-progress -> Dev]
  Story 1.4: Add password reset flow            [ready]
  Story 1.5: Add session management             [ready, depends on 1.2]

Next actions:
- Waiting for Remy's review of 1.2
- Dev is implementing 1.3
- 1.4 can begin once Dev is free

Blockers: None
```

### Talking to a Specific Agent

You can invoke any agent directly:

```
> penny, reprioritize the backlog -- password reset is more urgent than sessions
> aria, should we use JWT or session cookies?
> remy, what patterns have you seen in this codebase?
```

Or go through John, who will relay the message and context:

```
> john, ask Aria about the database indexing strategy
```

---

## Per-Project Structure

On first boot, John creates this structure inside your project:

```
.scrum/                         # Top-level — outside .claude/, so writes never trigger permission prompts
  status.md                     # Single source of truth for sprint state
  bus/
    2026-04-15.md               # Today's message bus (one file per day)
  memory/
    .john.md                    # John's project understanding
    .penny.md                   # Penny's product analysis
    .aria.md                    # Aria's architecture notes
    .dev.md                     # Dev's implementation knowledge
    .remy.md                    # Remy's code quality observations
    .tess.md                    # Tess's test strategy and findings
  docs/
    architecture.md             # Architecture decisions and system design
    tech-specs/
      epic-1-spec.md            # Technical specification per epic
    test-strategy.md            # Tess's test strategy document
```

All files are Markdown. All files are human-readable. You can inspect, edit, or
version-control them alongside your project code.

---

## Message Bus

Agents communicate via a daily message bus file at `.scrum/bus/YYYY-MM-DD.md`.
Messages are append-only within a day. Files older than 7 days are pruned on boot.

### Format

```markdown
# Scrum Bus -- 2026-04-15

## [14:32] John -> team: [STATUS] Sprint started
John: Beginning implementation of Epic 1. Dev is picking up Story 1.1.

---

## [14:35] Dev -> team: [STATUS] Story 1.1 complete
Dev: Implemented auth database schema. Files changed: src/db/schema.sql,
src/models/user.ts. All existing tests passing. Ready for review.

---

## [14:38] Remy -> Dev: [REVIEW] Story 1.1 approved
Remy: Schema looks clean. Good use of foreign keys and indexes. One
suggestion: consider adding a created_at default. Moving to testing.

---

## [14:42] Tess -> team: [STATUS] Story 1.1 tests passing
Tess: 12 tests written, all passing. Coverage: schema validation, constraint
enforcement, migration rollback. Story 1.1 is done.

---
```

### Message Types

| Prefix | Purpose |
|--------|---------|
| `[TASK]` | Assigning work to an agent |
| `[STATUS]` | Progress update or completion report |
| `[REVIEW]` | Code review feedback (approve or reject) |
| `[QUESTION]` | Requesting input from another agent |
| `[DECISION]` | Recording a team decision |
| `[BLOCK]` | Flagging a blocker |
| `[ESCALATE]` | Escalating to the user for input |

---

## Memory System

Each agent maintains a per-project memory file at `.scrum/memory/.{name}.md`.
Memory is written on first boot and updated whenever an agent's understanding of the
project changes.

### What Each Agent Remembers

| Agent | Focus Areas |
|-------|-------------|
| **John** | Project metadata, team coordination notes, key decisions, build/test commands |
| **Penny** | User personas, product gaps, feature inventory, prioritization rationale |
| **Aria** | Architecture patterns, tech debt, dependency graph, scalability concerns |
| **Dev** | Code patterns, build system, development workflow, file conventions |
| **Remy** | Code quality standards, security posture, review patterns, common issues |
| **Tess** | Test infrastructure, coverage gaps, test frameworks, testing patterns |

### How Memory Works

1. On **first boot**, each agent reads the codebase from their role's perspective
   and writes their initial memory file.
2. On **subsequent invocations**, each agent reads their memory file first to
   restore context before doing any work.
3. After **completing a task**, agents update their memory if their understanding
   of the project changed.

This means agents build institutional knowledge over time. Remy learns your
codebase's patterns. Tess knows your test framework quirks. Dev remembers which
conventions to follow.

---

## Story Lifecycle

Every story follows a strict lifecycle with clear ownership at each stage:

```
  backlog                   Penny drafts stories with ACs
     |
     v
  drafted  --------->  Aria reviews feasibility
     |
     v
  ready    --------->  Dev picks up implementation
     |
     v
  in-progress ------->  Dev writes code
     |
     v
  review   --------->  Remy reviews code quality
     |                    |
     |        (reject) <--+
     |           |
     |           v
     |     back to in-progress (max 3 cycles)
     |
     v
  testing  --------->  Tess runs tests
     |                    |
     |        (fail)  <---+
     |           |
     |           v
     |     back to in-progress
     |
     v
   done
```

- Only the designated agent can move a story to the next stage.
- Remy and Tess can send stories back for rework.
- After 3 failed review cycles, John escalates to the user.
- Any story can be marked `blocked` at any stage, with a documented reason.

---

## Configuration

The agents work out of the box with zero configuration. Customization is done by
editing the agent skill files directly:

| What | Where | How |
|------|-------|-----|
| Agent personality | `~/.claude/agents/{name}.md` | Edit the personality section |
| Model selection | `~/.claude/agents/{name}.md` | Change the `model:` field in frontmatter |
| Story format | `~/.claude/agents/penny.md` | Modify the story template |
| Review standards | `~/.claude/agents/remy.md` | Adjust review criteria |
| Test strategy | `~/.claude/agents/tess.md` | Change default test approaches |
| Bus retention | `~/.claude/agents/john.md` | Modify the 7-day prune window |

---

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Areas where help is most needed:

- Agent skill files for additional roles (DevOps, Security, Designer)
- Better parallelism strategies for multi-story sprints
- Integration with external project management tools
- Test coverage for the agents themselves
- Documentation improvements

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release history.

Upgrading from a release that used the old agent names (Fenny, Disha, Parminder,
David, Harpreet, Murat)? See [MIGRATION.md](MIGRATION.md).

### Current Status

This project is in active early development. All six agents (John, Penny, Aria,
Dev, Remy, and Tess) are implemented. The protocol specification is complete
and stable.

---

## License

Licensed under the [Apache License 2.0](LICENSE).

```
Copyright 2026 Ankit Agarwal

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0
```
