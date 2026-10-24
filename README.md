# Claude Code Defaults

Global configuration and reusable components for Claude Code development workflow.

## What's Included

### Global Configuration (`claude-config/`)

- **CLAUDE.md** - Global development standards, workflow, and testing philosophy (deployed to `~/.claude/CLAUDE.md`)
- **settings.sync.json** - Pre-approved permissions for safe commands, includes hook to prevent accidental edits on main
- **scripts/** - Shell utilities (deployed to `~/.claude/scripts/`)
  - `no-edit-main.py` - Hook blocking edits on the main branch. Type `!onmain` in a prompt to allow editing and committing on main for the rest of that session
  - `statusline.sh` - Status line with model, git status, sync state, context bar
  - `terminal-color.sh` - Per-session TTY-based color theming

### Agents (`claude-config/agents/`)

Workflow automation agents:

- `bug-fixer` - Implement a fix, run tests, QA, and commit in its own worktree
- `pre-work-check` - Verify branch and tests before starting work
- `test-expert` - Plan and review unit tests
- `test-scrutinizer` - Two-phase test plan review

### Skills (`claude-config/skills/`)

- `/start-feature <name>` - Create a feature branch and launch guided development
- `/completion-check` - Pre-merge checklist: tests, documentation, commit
- `/end-feature [push] [merge] [main] [clean]` - Commit, merge, push, and delete the branch
- `/parallel-fix`, `/parallel-feature` - Fan work out across isolated worktrees
- `/update-readme`, `/update-changelog`, `/update-project-spec`, `/update-claude-md` - Documentation updaters, each forked into its own context
- `/next`, `/issue` - Propose ready work and create linked issues in issue-tracked projects
- `/retro` - Review workflow and suggest improvements
- `/transcribe`, `/ssh-mcp`, `/script-writer`, `/xcodebuildmcp-cli` - Standalone tools

### Templates (`templates/`)

- `CLAUDE.md` - Project-level CLAUDE.md template
- `project_spec.md` - Project specification template

### Plugins

- **viam-claude** - Viam robotics platform development tools

## Installation

### Automated Sync (Recommended)

Use the built-in sync system to manage configuration:

```bash
# Clone this repository
git clone <repo-url>
cd claude-global-config

# Deploy to live config (installs plugins automatically)
./sync.sh deploy
```

### Manual Installation

Alternatively, manually copy files:
- `claude-config/CLAUDE.md` → `~/.claude/CLAUDE.md`
- `claude-config/agents/*` → `~/.claude/agents/*`
- `claude-config/skills/*` → `~/.claude/skills/*`
- `claude-config/settings.sync.json` → `~/.claude/settings.json`

## Configuration Sync

### Making Configuration Changes

1. **Experiment in Live Config**
   ```bash
   # Edit files in ~/.claude/ directly
   vim ~/.claude/CLAUDE.md
   # OR add a new agent
   vim ~/.claude/agents/my-new-agent.md
   ```

2. **Check Status**
   ```bash
   ./sync.sh status
   ```

3. **Preview Changes**
   ```bash
   ./sync.sh pull --dry-run
   ./sync.sh diff CLAUDE.md
   ```

4. **Pull Changes into Repo**
   ```bash
   ./sync.sh pull
   ```

5. **Review and Commit**
   ```bash
   git diff
   git add -A
   git commit -m "Update configuration from live experiments"
   git push
   ```

6. **Deploy on Other Machines**
   ```bash
   # On another machine
   git pull
   ./sync.sh deploy
   ```

See [README-SYNC.md](README-SYNC.md) for detailed sync documentation.

## Usage

1. Run `./sync.sh deploy` to install global config to `~/.claude/`
2. Copy `templates/CLAUDE.md` and `templates/project_spec.md` into new projects for project-level config
3. Use agents during development: `pre-work-check`, `test-scrutinizer`, `test-expert`, etc.

### Tracking project state in GitHub issues

By default a project keeps milestones, open questions, and technical debt in `project_spec.md`. To keep them in GitHub instead, add this line to the project's `CLAUDE.md`:

```
Tracking: GitHub issues (<owner>/<repo>)
```

A project spanning several repos names them all, and optionally the GitHub Project they share and the repos that Project auto-adds issues from:

```
Tracking: GitHub issues (<owner>/<repo>, <owner>/<repo>); project <owner>/<number>; auto-add <owner>/<repo>
```

With the line present:

- Milestones are GitHub milestones with plain-name titles. The description contains a `Check:` line, the owner's check before closing it. A milestone with work in several repos has a same-titled milestone in each.
- Open questions, technical debt, and planned work are issues. Questions and debt use the issue types `Question` and `Tech debt` in an organization's repos and the labels `question` and `tech-debt` in a personal account's; missing ones are created on first use.
- Dependencies are native blocked-by links between issues, across repos where needed.
- `/update-project-spec` files milestones, questions, and debt in the repo whose code they concern.
- `/next` proposes an open issue with no open blocker; `/issue` creates an issue with its milestone, links, and parent, and adds it to the Project.
- `/completion-check` lists the open milestones and the issues the branch closes.
- Commits that resolve an issue end with `Closes #N`, or `Closes <owner>/<repo>#N` for an issue in another repo.

#### Setting up a multi-repo project

These are done by hand in GitHub:

1. Put the repos in an organization (GitHub Free suffices); only organizations have issue types and issue fields.
2. Create one org-level Project and add the repos' existing issues to it.
3. Add a saved view filtered `is:open -is:blocked` and grouped by milestone. Grouping is set in the web UI.
4. Turn on the built-in workflow that moves closed items to Done.
5. Optionally, turn on auto-add for one repo (GitHub Free allows one auto-add workflow) and name that repo after `auto-add` in the Tracking line.

## Workflow

See `claude-config/CLAUDE.md` for the complete development workflow, including:
- Starting work on feature branches
- Two-phase test scrutiny
- Parallel documentation updates on commit
- Pre-merge quality checks

## Philosophy

- **Self-documenting code over comments**
- **Test custom logic, not libraries**
- **Never discard uncommitted work**
- **Separate concerns**: Global CLAUDE.md (standards) vs project CLAUDE.md (project context) vs project_spec.md (technical) vs README.md (users)
