# Migrating to the Renamed Agents

The agents have been renamed twice. In **v0.3.0** the six agents moved from real-person names to neutral
names. In **v0.4.0** the Developer was renamed once more, from **Dev** to **Dave** (because "Dev" collided
with the generic word for the role — "put a dev on it" could mean the agent or any developer). The roles,
workflows, message bus, and `.scrum/` data format are all unchanged — only the names moved. This guide gets
you to the current names.

| Role | Original name | Current name | Original file | Current file |
|------|---------------|--------------|---------------|--------------|
| Scrum Master / Orchestrator | Fenny | **John** | `fenny.md` | `john.md` |
| Product Manager | Disha | **Penny** | `disha.md` | `penny.md` |
| Architect | Parminder | **Aria** | `parminder.md` | `aria.md` |
| Developer | David | **Dave** | `david.md` | `dave.md` |
| Code Reviewer | Harpreet | **Remy** | `harpreet.md` | `remy.md` |
| Tester | Murat | **Tess** | `murat.md` | `tess.md` |

> The Developer went **David → Dev → Dave**: real name in v0.1.x, "Dev" in v0.3.x, "Dave" from v0.4.0.
> Migration handles every hop — a `.scrum/memory/.david.md` *or* `.dev.md` is moved to `.dave.md`.

There are two things to migrate: the **installed agent files** (global, one-time) and the **per-project
runtime data** (per project, automatic).

## 1. Update the installed agents

```bash
git pull
./install.sh
```

`install.sh` removes the old agent files from `~/.claude/agents/` (`fenny.md` / `disha.md` / `parminder.md` /
`david.md` / `dev.md` / `harpreet.md` / `murat.md`) and installs the six current files. (Doing it by hand
instead? Delete those files and copy the new ones from `agents/`.)

Verify:

```bash
ls ~/.claude/agents/
# Expect: john.md penny.md aria.md dave.md remy.md tess.md  — and none of the old names.
```

## 2. Migrate per-project runtime data (automatic)

Each project where you used the team has a `.scrum/` directory with per-agent memory keyed by an **old**
name (`.scrum/memory/.fenny.md`, `.scrum/memory/.dev.md`, etc.). You do **not** need to touch these by hand —
there are two ways they get migrated, and both are idempotent:

- **`./install.sh`** migrates the `.scrum/` of the project it is run *from*. If you run the installer inside
  a project directory, that project is migrated as part of the install.
- **Invoking John** migrates the project he boots in. The first time you invoke **John** in a project, he
  detects old-named memory files and renames them, preserving each agent's accumulated memory:

```
.scrum/memory/.fenny.md     → .scrum/memory/.john.md
.scrum/memory/.disha.md     → .scrum/memory/.penny.md
.scrum/memory/.parminder.md → .scrum/memory/.aria.md
.scrum/memory/.david.md     → .scrum/memory/.dave.md
.scrum/memory/.dev.md       → .scrum/memory/.dave.md
.scrum/memory/.harpreet.md  → .scrum/memory/.remy.md
.scrum/memory/.murat.md     → .scrum/memory/.tess.md
```

He posts a `[STATUS]` to the bus noting the migration. Until John has run, the specialists will refuse to
bootstrap fresh on a pre-rename project (which would orphan the old memory) and will ask you to invoke John
first.

```
> john, pick up where we left off
```

### Already on v0.3.x? (Dev → Dave only)

If you already migrated to the neutral names in v0.3.0, the only change in v0.4.0 is the Developer:
`.scrum/memory/.dev.md` becomes `.dave.md`, and the installed `dev.md` becomes `dave.md`. Both happen
automatically through the same install / John-boot migration above — nothing extra to do.

### Doing it manually (optional)

If you'd rather migrate without invoking John, rename the files yourself from the project root (each line is
a no-op if that old file isn't present):

```bash
cd .scrum/memory
mv .fenny.md     .john.md  2>/dev/null
mv .disha.md     .penny.md 2>/dev/null
mv .parminder.md .aria.md  2>/dev/null
mv .david.md     .dave.md  2>/dev/null
mv .dev.md       .dave.md  2>/dev/null
mv .harpreet.md  .remy.md  2>/dev/null
mv .murat.md     .tess.md  2>/dev/null
```

## 3. Existing status / bus / docs (no action needed)

`.scrum/status.md`, the bus history, and the docs may still mention old names (e.g. `Assigned: David`,
`Owner: Disha`, or `→ Dev`). This is harmless — it's historical content, and the renamed agents read and
operate on it normally. New entries use the current names. Search-and-replace if you want full consistency,
but it isn't required.

## Rolling back

Re-install the previous release's agents and rename the memory files back (the reverse of step 2's manual
commands — `.dave.md` → `.dev.md` to return to v0.3.x, or → `.david.md` for v0.1.x). The `.scrum/` data
format is unchanged across the renames, so no data is lost in either direction.
