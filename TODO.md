# TODO: Remaining Improvement Opportunities

---

## Functional Gaps

### 2. Missing sync for templates directory

`templates/project_spec.md` exists but isn't synced to `~/.claude/templates/` for global access.

**Fix:** Add to `.sync-config.yaml`:
```yaml
directories:
  - source: templates
    target: ~/.claude/templates
```

### 3. No sync for `.claude/test-proposals/`

CLAUDE.md references `.claude/test-proposals/<branch-name>.md` but this directory isn't in the sync configuration.

**Note:** This is a live-only directory (generated during workflow), probably shouldn't sync back to repo.

---

## Robustness Issues

### 4. Platform-specific code in `format_file_details()`

**Location:** `lib/sync-core.sh:334` (line number may have changed)

```bash
stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$file"
```

This is macOS syntax. GNU `stat` (Linux) uses `--format`.

**Fix:** Detect platform and use appropriate syntax.

### 5. Plugin list parsing is fragile

**Location:** `lib/sync-core.sh:456` (line number may have changed)

```bash
grep -E '^\s+❯' | awk '{print $2}'
```

This depends on exact `claude plugin list` output format which may change.

**Fix:** Use a more robust parsing method or handle format changes gracefully.

---

## Missing Features

### 6. No `rollback` command

Backups are created but no easy way to restore from them.

**Suggested commands:**
```bash
./sync.sh rollback [file] [timestamp]
./sync.sh backups list
```

### 7. No `verify` command

Would confirm live config matches expected state after deploy:
```bash
./sync.sh verify  # Exit 0 if in sync, non-zero otherwise
```

### 8. No `uninstall` / `reset` command

No way to cleanly remove the configuration or reset to defaults.

---

## Documentation & Conventions

### 9. `settings.sync.json` naming convention undocumented

The `.sync` suffix isn't explained anywhere—clarify that files with `.sync` in the name have repo-canonical versions that differ from live files.

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

### 12. Project scaffolding from templates

Templates exist (`templates/CLAUDE.md`, `templates/project_spec.md`) but there's no automated way to scaffold a new project from them. Consider a skill or command that copies templates into a target directory and fills in placeholders.

---

## Recently Completed

✓ **Branch naming convention aligned across all files** (2026-02-06)
  - Updated pre-work-check agent to match `<user>/feature-*` and `<user>/fix-*` patterns from CLAUDE.md
  - Fixed start-feature skill description and examples to use the same convention

✓ **`.sync-config.yaml` is now used programmatically** (2026-02-05)
  - Implemented config-driven sync using `yq`
  - All sync commands now parse YAML instead of using hardcoded paths
