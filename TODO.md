# TODO: Remaining Improvement Opportunities

---

## Functional Gaps

### 1. Missing sync for templates directory

`templates/` exists but isn't synced to `~/.claude/templates/` for global access.

**Fix:** Add to `.sync-config.yaml`:
```yaml
directories:
  - source: templates
    target: ~/.claude/templates
```

### 2. No sync for `.claude/test-proposals/`

The global CLAUDE.md references `.claude/test-proposals/<branch-name>.md` but this directory isn't in the sync configuration. This is a live-only directory generated during workflow and likely shouldn't sync back to repo.

---

## Robustness Issues

### 3. Platform-specific code in `format_file_details()`

**Location:** `lib/sync-core.sh` (in `format_file_details`)

```bash
stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$file"
```

This is macOS syntax. GNU `stat` (Linux) uses `--format`.

**Fix:** Detect platform and use appropriate syntax.

### 4. Plugin list parsing is fragile

**Location:** `lib/sync-core.sh` (in plugin sync functions)

```bash
grep -E '^\s+❯' | awk '{print $2}'
```

This depends on exact `claude plugin list` output format which may change.

**Fix:** Use a more robust parsing method or handle format changes gracefully.

---

## Missing Features

### 5. No `rollback` command

Backups are created but no easy way to restore from them.

**Suggested commands:**
```bash
./sync.sh rollback [file] [timestamp]
./sync.sh backups list
```

### 6. No `verify` command

Would confirm live config matches expected state after deploy:
```bash
./sync.sh verify  # Exit 0 if in sync, non-zero otherwise
```

### 7. No `uninstall` / `reset` command

No way to cleanly remove the configuration or reset to defaults.

### 8. Project start script

Write a script or skill that scaffolds a new project from templates (`templates/CLAUDE.md`, `templates/project_spec.md`), copies them into a target directory, and fills in placeholders.

---

## Documentation & Conventions

### 9. `settings.sync.json` naming convention undocumented

The `.sync` suffix isn't explained anywhere — clarify that files with `.sync` in the name have repo-canonical versions that differ from live files.

### 10. Viam plugin should be optional

The `viam-claude/` directory is domain-specific.

**Options:**
- Move to a separate repo
- Document it as an optional plugin example

### 11. `install.sh` redundancy

`./sync.sh deploy` does everything `install.sh` does and more.

**Options:**
- Remove `install.sh`
- Make it a wrapper: `exec ./sync.sh deploy "$@"`
- Keep it as a simple entry point for new users

### 12. viam-claude/README.md is out of date

Lists skills that don't exist (`/cycle`, `/trial-start`, `/trial-stop`, `/trial-status`) and is missing skills that do (`/dataset-create`, `/dataset-delete`, `/viam-guide`). Install path references a stale location.

---

## Recently Completed

✓ **Split CLAUDE.md into global and project-level files** (2026-02-06)
  - Global config moved to `claude-config/CLAUDE.md`
  - Repo root CLAUDE.md rewritten as project-specific config
  - Added `templates/CLAUDE.md` for new projects
  - Simplified claude-md-updater and project-spec-updater agents
  - Streamlined README-SYNC.md, removed stale API key instructions

✓ **Branch naming convention aligned across all files** (2026-02-06)
  - Updated pre-work-check agent to match `<user>/feature-*` and `<user>/fix-*` patterns from CLAUDE.md
  - Fixed start-feature skill description and examples to use the same convention

✓ **`.sync-config.yaml` is now used programmatically** (2026-02-05)
  - Implemented config-driven sync using `yq`
  - All sync commands now parse YAML instead of using hardcoded paths
