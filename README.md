# AI Agents

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Claude Code](https://img.shields.io/badge/Built_for-Claude_Code-blueviolet)](https://claude.ai/claude-code)
[![Agents](https://img.shields.io/badge/Agents-6-green)]()

**A complete AI-powered scrum team, built as Claude Code agents.**

Six specialized agents collaborate to plan, architect, implement, review, and test
software projects autonomously. They are pure skill files (`.md`) that install to
`~/.claude/agents/` and work on ANY project -- no framework, no runtime, no dependencies.

```
 You: "Build me a REST API for task management"

 Fenny: Got it. Spawning Disha for story breakdown...
        Disha drafted 5 stories. Parminder is reviewing architecture.
        Plan ready. Shall I proceed?

 You: "Go"

 Fenny: David is implementing Story 1.1 (project scaffold)...
        Harpreet approved. Murat's tests passing. Story 1.1 done.
        David is starting Story 1.2...
```

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
| **Fenny** | Scrum Master & Orchestrator | `green` | Warm but efficient. Never writes code. Spawns and coordinates all agents. |
| **Disha** | Product Manager | `blue` | User-focused. Breaks goals into epics and stories with precise acceptance criteria. |
| **Parminder** | Architect | `cyan` | Deep technical thinker. Owns system design, tech specs, and feasibility review. |
| **David** | Developer | `yellow` | Methodical implementer. Follows conventions, writes clean production code. |
| **Harpreet** | Code Reviewer | `red` | Quality gatekeeper. Thorough but fair. Will block bad code without hesitation. |
| **Murat** | Tester | `magenta` | Quality obsessive. Writes all test types. Performs live UI testing when needed. |

Fenny is the only agent you need to invoke directly. She spawns the rest as
sub-agents via Claude Code's Task tool, passing each one full project context.

---

## How It Works

1. **You describe what you want.** Talk to Fenny naturally -- a feature, a fix, an entire project.
2. **Fenny spawns Disha** to write the epic and break it into stories with acceptance criteria.
3. **Parminder reviews** each story for technical feasibility, writes a tech spec, and marks stories as "ready."
4. **David implements** ready stories, one at a time or in parallel when they touch different files.
5. **Harpreet reviews** David's code -- approves or rejects with specific, actionable feedback.
6. **Murat tests** approved stories against the acceptance criteria and edge cases.
7. **Fenny tracks it all**, updates status, mediates conflicts, and reports progress to you.

Every action is logged on a shared message bus. Every agent maintains per-project
memory. Sprint state lives in a single status file. The entire system is resumable --
you can close your terminal, come back tomorrow, and Fenny picks up exactly where
she left off.

---

## Architecture

```
                          +-----------+
                          |    You    |
                          +-----+-----+
                                |
                                v
                    +-----------+-----------+
                    |       Fenny           |
                    |  (Scrum Master)       |
                    |  Orchestrates all     |
                    |  agents via Task tool |
                    +-+---+---+---+---+----+
                      |   |   |   |   |
          +-----------+   |   |   |   +------------+
          |               |   |   |                |
          v               v   |   v                v
    +----------+  +---------+ | +-----------+ +----------+
    |  Disha   |  |Parminder| | | Harpreet  | |  Murat   |
    |   (PM)   |  |  (Arch) | | | (Reviewer)| | (Tester) |
    +----------+  +---------+ | +-----------+ +----------+
                              v
                        +----------+
                        |  David   |
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
- **Fenny is the single orchestrator.** She is the only agent that spawns others.
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
  fenny.md        # Scrum Master & Orchestrator
  disha.md        # Product Manager
  parminder.md    # Architect
  david.md        # Developer
  harpreet.md     # Code Reviewer
  murat.md        # Tester
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

Navigate to any project and invoke Fenny:

```
> fenny, initialize the scrum team for this project
```

Fenny will:
1. Create the `.scrum/` directory structure
2. Read your codebase to understand the project
3. Spawn all five agents in parallel for first-boot analysis
4. Report when everyone is ready

```
Scrum team initialized for my-web-app.
  Disha (PM): Ready -- identified 3 existing features and 5 product gaps
  Parminder (Architect): Ready -- mapped architecture and tech debt
  David (Developer): Ready -- cataloged code patterns and build system
  Harpreet (Reviewer): Ready -- assessed code quality and standards
  Murat (Tester): Ready -- evaluated test coverage and frameworks

Awaiting your direction. What would you like us to build?
```

### Creating an Epic

```
> fenny, build a user authentication system with email/password login,
  registration, password reset, and session management
```

Fenny spawns Disha, who drafts the epic and stories. Then Parminder reviews for
technical feasibility. You get a plan to approve before any code is written.

### Running a Sprint

```
> fenny, start implementing the approved stories
```

Fenny identifies dependency waves and begins spawning David for independent stories
in parallel. As each story completes, Harpreet reviews and Murat tests.

### Checking Status

```
> fenny, what's the sprint status?
```

```
Sprint Progress:

Epic 1: User Authentication [in-progress]
  Story 1.1: Set up auth database schema       [done]
  Story 1.2: Implement registration endpoint    [review -> Harpreet]  (cycle 1/3)
  Story 1.3: Implement login endpoint           [in-progress -> David]
  Story 1.4: Add password reset flow            [ready]
  Story 1.5: Add session management             [ready, depends on 1.2]

Next actions:
- Waiting for Harpreet's review of 1.2
- David is implementing 1.3
- 1.4 can begin once David is free

Blockers: None
```

### Talking to a Specific Agent

You can invoke any agent directly:

```
> disha, reprioritize the backlog -- password reset is more urgent than sessions
> parminder, should we use JWT or session cookies?
> harpreet, what patterns have you seen in this codebase?
```

Or go through Fenny, who will relay the message and context:

```
> fenny, ask Parminder about the database indexing strategy
```

---

## Per-Project Structure

On first boot, Fenny creates this structure inside your project:

```
.scrum/                         # Top-level — outside .claude/, so writes never trigger permission prompts
  status.md                     # Single source of truth for sprint state
  bus/
    2026-04-15.md               # Today's message bus (one file per day)
  memory/
    .fenny.md                   # Fenny's project understanding
    .disha.md                   # Disha's product analysis
    .parminder.md               # Parminder's architecture notes
    .david.md                   # David's implementation knowledge
    .harpreet.md                # Harpreet's code quality observations
    .murat.md                   # Murat's test strategy and findings
  docs/
    architecture.md             # Architecture decisions and system design
    tech-specs/
      epic-1-spec.md            # Technical specification per epic
    test-strategy.md            # Murat's test strategy document
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

## [14:32] Fenny -> team: [STATUS] Sprint started
Fenny: Beginning implementation of Epic 1. David is picking up Story 1.1.

---

## [14:35] David -> team: [STATUS] Story 1.1 complete
David: Implemented auth database schema. Files changed: src/db/schema.sql,
src/models/user.ts. All existing tests passing. Ready for review.

---

## [14:38] Harpreet -> David: [REVIEW] Story 1.1 approved
Harpreet: Schema looks clean. Good use of foreign keys and indexes. One
suggestion: consider adding a created_at default. Moving to testing.

---

## [14:42] Murat -> team: [STATUS] Story 1.1 tests passing
Murat: 12 tests written, all passing. Coverage: schema validation, constraint
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
| **Fenny** | Project metadata, team coordination notes, key decisions, build/test commands |
| **Disha** | User personas, product gaps, feature inventory, prioritization rationale |
| **Parminder** | Architecture patterns, tech debt, dependency graph, scalability concerns |
| **David** | Code patterns, build system, development workflow, file conventions |
| **Harpreet** | Code quality standards, security posture, review patterns, common issues |
| **Murat** | Test infrastructure, coverage gaps, test frameworks, testing patterns |

### How Memory Works

1. On **first boot**, each agent reads the codebase from their role's perspective
   and writes their initial memory file.
2. On **subsequent invocations**, each agent reads their memory file first to
   restore context before doing any work.
3. After **completing a task**, agents update their memory if their understanding
   of the project changed.

This means agents build institutional knowledge over time. Harpreet learns your
codebase's patterns. Murat knows your test framework quirks. David remembers which
conventions to follow.

---

## Story Lifecycle

Every story follows a strict lifecycle with clear ownership at each stage:

```
  backlog                   Disha drafts stories with ACs
     |
     v
  drafted  --------->  Parminder reviews feasibility
     |
     v
  ready    --------->  David picks up implementation
     |
     v
  in-progress ------->  David writes code
     |
     v
  review   --------->  Harpreet reviews code quality
     |                    |
     |        (reject) <--+
     |           |
     |           v
     |     back to in-progress (max 3 cycles)
     |
     v
  testing  --------->  Murat runs tests
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
- Harpreet and Murat can send stories back for rework.
- After 3 failed review cycles, Fenny escalates to the user.
- Any story can be marked `blocked` at any stage, with a documented reason.

---

## Configuration

The agents work out of the box with zero configuration. Customization is done by
editing the agent skill files directly:

| What | Where | How |
|------|-------|-----|
| Agent personality | `~/.claude/agents/{name}.md` | Edit the personality section |
| Model selection | `~/.claude/agents/{name}.md` | Change the `model:` field in frontmatter |
| Story format | `~/.claude/agents/disha.md` | Modify the story template |
| Review standards | `~/.claude/agents/harpreet.md` | Adjust review criteria |
| Test strategy | `~/.claude/agents/murat.md` | Change default test approaches |
| Bus retention | `~/.claude/agents/fenny.md` | Modify the 7-day prune window |

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

### Current Status

This project is in active early development. All six agents (Fenny, Disha, Parminder,
David, Harpreet, and Murat) are implemented. The protocol specification is complete
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
