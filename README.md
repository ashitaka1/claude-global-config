# claude-global-config (retired)

This repo no longer manages Claude Code's configuration. Don't run `./sync.sh` from it: `~/.claude/CLAUDE.md` and `settings.json` are now symlinks, and a deploy would overwrite their targets.

| What | Where now |
|------|-----------|
| Global `CLAUDE.md`, `settings.json`, status line | [`ashitaka1/machine-setup`](https://github.com/ashitaka1/machine-setup), `claude/`, symlinked into `~/.claude` by `link.sh` |
| Skills and agents | plugins in the `avery-plugins` marketplace, [`ashitaka1/claude-skills`](https://github.com/ashitaka1/claude-skills): `dev-workflow` (testing-fundamentals, test-scrutinizer, `/next`, `/issue`, `update-docs`) and `dev-tools` (transcribe, xcodebuildmcp-cli, ssh-mcp) |
| Feature workflow | the `superpowers` plugin, configured by the global `CLAUDE.md` |
| Personal `viam-claude` skills | `claude-skills/archive/viam-claude` |
| `script-writer` | `demo-techm/.claude/skills` |
| Merging with Viam's shared config | milestone "Viam shared config" in `machine-setup` and `claude-skills` |

## Moving a machine to the new setup

On a machine where this repo's `sync.sh` deployed the old config:

```sh
# 1. Get the new config and link it in. Existing CLAUDE.md, settings.json,
#    and status line scripts are kept as *.bak.<timestamp>.
cd ~/eng/machine-setup && git pull
./bootstrap.sh --link-only

# 2. Install the plugins settings.json enables. --link-only skips this step.
bash claude/plugins.sh

# 3. Move the old personal skills, agents, and main-branch guard aside.
#    Plugins replace them; leaving them would duplicate /next and /issue.
R=~/.claude/retired-$(date +%F); mkdir -p $R/skills $R/agents $R/scripts
for s in start-feature end-feature completion-check update-changelog update-claude-md \
         update-project-spec update-readme retro parallel-feature parallel-fix shared \
         next issue transcribe xcodebuildmcp-cli ssh-mcp script-writer; do
  [ -e ~/.claude/skills/$s ] && mv ~/.claude/skills/$s $R/skills/
done
for a in bug-fixer test-expert test-scrutinizer pre-work-check; do
  [ -e ~/.claude/agents/$a.md ] && mv ~/.claude/agents/$a.md $R/agents/
done
[ -e ~/.claude/scripts/no-edit-main.py ] && mv ~/.claude/scripts/no-edit-main.py $R/scripts/

# 4. Remove the plugins the new setup dropped.
claude plugin uninstall feature-dev@claude-plugins-official --scope user
claude plugin uninstall code-simplifier@claude-plugins-official --scope user
```

Restart Claude Code. `claude plugin list` shows `dev-workflow` and `dev-tools`, and `ls -l ~/.claude/CLAUDE.md` points into `machine-setup`.

A machine without `machine-setup` needs only:

```sh
git clone git@github.com:ashitaka1/machine-setup.git ~/eng/machine-setup
cd ~/eng/machine-setup && ./bootstrap.sh
```

The `avery-plugins` marketplace clones over SSH, so the machine needs a GitHub SSH key.

## After that

- Global config: edit in `machine-setup/claude/`, commit, and `git pull` on other machines; the links pick it up.
- Skills and agents: change them in `claude-skills`, bump the plugin's `version`, push, and run `claude plugin update <plugin>@avery-plugins`.
