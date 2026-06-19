# Migrating to the Renamed Agents (v0.3.0)

In v0.3.0 the six agents were renamed from real-person names to neutral names. The roles,
workflows, message bus, and `.scrum/` data format are all unchanged — only the names moved.

| Role | Old name | New name | Old file | New file |
|------|----------|----------|----------|----------|
| Scrum Master / Orchestrator | Fenny | **John** | `fenny.md` | `john.md` |
| Product Manager | Disha | **Penny** | `disha.md` | `penny.md` |
| Architect | Parminder | **Aria** | `parminder.md` | `aria.md` |
| Developer | David | **Dev** | `david.md` | `dev.md` |
| Code Reviewer | Harpreet | **Remy** | `harpreet.md` | `remy.md` |
| Tester | Murat | **Tess** | `murat.md` | `tess.md` |

There are two things to migrate: the **installed agent files** (global, one-time) and the
**per-project runtime data** (per project, automatic).

## 1. Update the installed agents

```bash
git pull
./install.sh
```

`install.sh` removes the old `fenny.md` / `disha.md` / `parminder.md` / `david.md` / `harpreet.md` /
`murat.md` files from `~/.claude/agents/` and installs the six renamed files. (Doing it by hand instead?
Delete those six files and copy the new ones from `agents/`.)

Verify:

```bash
ls ~/.claude/agents/
# Expect: john.md penny.md aria.md dev.md remy.md tess.md  — and none of the old names.
```

## 2. Migrate per-project runtime data (automatic)

Each project where you used the team has a `.scrum/` directory with per-agent memory keyed by the **old**
names (`.scrum/memory/.fenny.md`, etc.). You do **not** need to touch these by hand — there are two ways
they get migrated, and both are idempotent:

- **`./install.sh`** migrates the `.scrum/` of the project it is run *from*. If you run the installer
  inside a project directory, that project is migrated as part of the install.
- **Invoking John** migrates the project he boots in. The first time you invoke **John** in a project, he
  detects the old-named memory files and renames them, preserving each agent's accumulated memory:

```
.scrum/memory/.fenny.md     → .scrum/memory/.john.md
.scrum/memory/.disha.md     → .scrum/memory/.penny.md
.scrum/memory/.parminder.md → .scrum/memory/.aria.md
.scrum/memory/.david.md     → .scrum/memory/.dev.md
.scrum/memory/.harpreet.md  → .scrum/memory/.remy.md
.scrum/memory/.murat.md     → .scrum/memory/.tess.md
```

He posts a `[STATUS]` to the bus noting the migration. Until John has run, the specialists will refuse to
bootstrap fresh on a pre-rename project (which would orphan the old memory) and will ask you to invoke John
first.

```
> john, pick up where we left off
```

### Doing it manually (optional)

If you'd rather migrate without invoking John, rename the files yourself from the project root:

```bash
cd .scrum/memory
mv .fenny.md     .john.md  2>/dev/null
mv .disha.md     .penny.md 2>/dev/null
mv .parminder.md .aria.md  2>/dev/null
mv .david.md     .dev.md   2>/dev/null
mv .harpreet.md  .remy.md  2>/dev/null
mv .murat.md     .tess.md  2>/dev/null
```

## 3. Existing status / bus / docs (no action needed)

`.scrum/status.md`, the bus history, and the docs may still mention the old names (e.g. `Assigned: David`,
`Owner: Disha`). This is harmless — it's historical content, and the renamed agents read and operate on it
normally. New entries use the new names. Search-and-replace if you want full consistency, but it isn't
required.

## Rolling back

Re-install the previous release's agents and rename the memory files back (the reverse of step 2's manual
commands). The `.scrum/` data format is unchanged across the rename, so no data is lost in either direction.
