# TODO: Remaining Improvement Opportunities

---

## Functional Gaps

### 1. No sync for `.claude/test-proposals/`

The global CLAUDE.md references `.claude/test-proposals/<branch-name>.md` but this directory isn't in the sync configuration. This is a live-only directory generated during workflow and likely shouldn't sync back to repo.

---

## Robustness Issues

### 2. Platform-specific code in `format_file_details()`

**Location:** `lib/sync-core.sh` (in `format_file_details`)

```bash
stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$file"
```

This is macOS syntax. GNU `stat` (Linux) uses `--format`.

**Fix:** Detect platform and use appropriate syntax.

### 3. Plugin list parsing is fragile

**Location:** `lib/sync-core.sh` (in plugin sync functions)

```bash
grep -E '^\s+❯' | awk '{print $2}'
```

This depends on exact `claude plugin list` output format which may change.

**Fix:** Use a more robust parsing method or handle format changes gracefully.

---

## Missing Features

### 4. No `rollback` command

Backups are created but no easy way to restore from them.

**Suggested commands:**
```bash
./sync.sh rollback [file] [timestamp]
./sync.sh backups list
```

### 5. No `verify` command

Would confirm live config matches expected state after deploy:
```bash
./sync.sh verify  # Exit 0 if in sync, non-zero otherwise
```

### 6. No `uninstall` / `reset` command

No way to cleanly remove the configuration or reset to defaults.

### 7. Project start script

Write a script or skill that scaffolds a new project from templates (`templates/CLAUDE.md`, `templates/project_spec.md`), copies them into a target directory, and fills in placeholders.

---

## Documentation & Conventions

### 8. Viam plugin should be optional

The `viam-claude/` directory is domain-specific.

**Options:**
- Move to a separate repo
- Document it as an optional plugin example

---

## Recently Completed

✓ **Consolidated scripts directory and rewrote statusline** (2026-02-06)
  - Moved `api_key_helper.sh` and `statusline.sh` into `claude-config/scripts/`
  - Rewrote statusline with model name, context window bar, remote sync status, per-session color theming, and last user message
  - Added `terminal-color.sh` for TTY-based per-session accent colors
  - Updated `.sync-config.yaml` to use directory sync for scripts
  - Updated settings, README-SYNC.md, and project CLAUDE.md

✓ **Simple doc and config fixes** (2026-02-06)
  - Documented `.sync` suffix naming convention in README-SYNC.md
  - Updated viam-claude/README.md with correct skills and install path
  - Made `install.sh` chain into `sync.sh deploy` after installing dependencies
  - Added `templates/` directory to sync config

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
