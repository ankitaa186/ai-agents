# Contributing to AI Agents

Thank you for your interest in contributing to the AI scrum team project. This guide covers everything you need to know to submit a contribution.

## Table of Contents

- [How the Project Works](#how-the-project-works)
- [Agent File Format](#agent-file-format)
- [How to Contribute](#how-to-contribute)
- [Testing Your Changes](#testing-your-changes)
- [Pull Request Process](#pull-request-process)
- [Adding a New Agent](#adding-a-new-agent)
- [Modifying the Shared Protocol](#modifying-the-shared-protocol)
- [Coding Standards](#coding-standards)
- [Code of Conduct](#code-of-conduct)

## How the Project Works

This is not a traditional software project. There is no application code, no build step, and no runtime dependencies. The entire project is **prompt engineering** expressed as Markdown files.

Each agent is a `.md` file that lives in `agents/` and gets installed to `~/.claude/agents/`. Claude Code loads these files as agent definitions. The shared conventions are documented in `PROTOCOL.md`, which serves as a design reference (it is not installed).

## Agent File Format

Every agent file in `agents/` is a Markdown document with two parts:

1. **YAML frontmatter** -- metadata between `---` fences at the top of the file. This includes fields like the agent's name, description, and any tool permissions.

2. **Instructions body** -- the Markdown content after the frontmatter. This is the prompt that defines the agent's personality, responsibilities, workflows, and interaction patterns.

Example structure:

```markdown
---
name: agent-name
description: One-line summary of what this agent does
---

# Agent Name -- Role Title

## Identity

Who the agent is and how it behaves.

## Responsibilities

What the agent owns.

## Workflows

Step-by-step procedures the agent follows.
```

## How to Contribute

1. **Fork the repository** and create a feature branch from `main`.
2. **Make your changes** following the standards described below.
3. **Test locally** (see [Testing Your Changes](#testing-your-changes)).
4. **Open a pull request** against `main`.

If you are unsure whether a change is welcome, open an issue first to discuss it.

## Testing Your Changes

Since agent files are loaded by Claude Code at runtime, the testing process is manual:

1. **Install locally.** Copy the modified agent file(s) to `~/.claude/agents/`:

   ```bash
   cp agents/fenny.md ~/.claude/agents/fenny.md
   ```

2. **Open a test project.** Use a scratch project directory -- do not test against a production codebase.

3. **Invoke the agent.** In Claude Code, address the agent by name (e.g., type `fenny, ...` in the chat) or pick it from the `/agents` menu, and exercise the workflows you changed. Agents are routed automatically based on their `description` and `<example>` blocks.

4. **Verify behavior.** Confirm that:
   - The agent responds according to its defined role.
   - It follows the shared protocol conventions.
   - It does not produce errors or break other agents' workflows.
   - Any new workflows execute end-to-end.

5. **Cross-agent testing.** If your change affects inter-agent communication (the message bus, status file, or handoff patterns), test at least one full interaction cycle between the relevant agents.

## Pull Request Process

1. **One logical change per PR.** Do not bundle unrelated agent changes.
2. **Describe what changed and why** in the PR description. Include before/after examples of agent behavior if relevant.
3. **Link related issues** if applicable.
4. **All PRs require review** before merging. A maintainer will review for clarity, protocol compliance, and potential side effects on other agents.
5. **Address review feedback** by pushing additional commits (do not force-push over review comments).

## Adding a New Agent

To add a new agent to the scrum team:

1. **Create the agent file** in `agents/` following the [agent file format](#agent-file-format).
2. **Register the agent in `PROTOCOL.md`** so other agents and contributors know it exists. Add it to the installation list and describe its role.
3. **Define inter-agent boundaries.** Be explicit about what the new agent owns and how it communicates with existing agents (via the message bus, status file, or direct handoff).
4. **Update `README.md`** to include the new agent in the team roster.
5. **Test the agent in isolation** and then in combination with at least one other agent.

## Modifying the Shared Protocol

`PROTOCOL.md` defines conventions that all agents follow: the directory structure, message bus format, status file schema, and communication patterns. Changes here affect every agent.

- **Propose protocol changes in an issue first.** These changes have a wide blast radius.
- **Update all affected agent files** in the same PR. A protocol change without corresponding agent updates will break the team.
- **Document the rationale** for the change in the PR description.

## Coding Standards

Agent files are prompts, not code, but they still benefit from consistent standards:

- **Clear instructions.** Write in direct, imperative language. Avoid ambiguity.
- **Self-contained.** Each agent file should include everything Claude Code needs to fulfill that role. Do not rely on implicit knowledge.
- **Project-agnostic.** Agents must work in any project directory. Never hard-code paths, project names, or technology-specific assumptions.
- **Consistent structure.** Follow the existing section layout (Identity, Responsibilities, Workflows, etc.) so agents are easy to navigate and compare.
- **Minimal scope.** Each agent should do one job well. If an agent's instructions exceed a reasonable length, consider whether it is doing too much.
- **Protocol compliance.** All agents must follow the conventions in `PROTOCOL.md` for file paths, message formats, and handoff patterns.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/). By participating, you agree to uphold a welcoming, inclusive, and harassment-free environment for everyone.

If you experience or witness unacceptable behavior, please open an issue or contact a maintainer directly.

## License

By contributing, you agree that your contributions will be licensed under the [Apache License 2.0](LICENSE).
