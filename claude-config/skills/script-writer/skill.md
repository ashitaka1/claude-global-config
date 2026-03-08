---
name: script-writer
description: Walk through the demo outline interactively, building chapters and maintaining the presenter script. Use when continuing demo development work — picking up where the last session left off.
disable-model-invocation: false
---

Resume interactive demo development for the Viam demo module project.

## Usage

```
/script-writer
```

## What it does

Picks up demo development from where the last session left off. The workflow is collaborative — walk through the demo outline with the user act by act, chapter by chapter:

1. **Read state** — Check `script.md` for what's been scripted, `CLAUDE.md` "Script Progress" section for current position, and `project_spec.md` chapter map for what's done (✅) vs pending (⏳).

2. **Resume at current position** — Pick up at the next unfinished chapter or act segment. Remind the user where we left off.

3. **For each segment, interactively:**
   - Discuss what happens in this segment (what the presenter does, says, shows)
   - If it's a Builder UI segment: document what the presenter does in `script.md`
   - If it's a code chapter: build the module code, test it, deploy it, then document in `script.md`
   - Ask the user what comes next rather than assuming

4. **Update `script.md`** as segments are finalized — this is the presenter's cue card document.

5. **Update CLAUDE.md "Script Progress"** to track current position after each segment.

## Key principles

- **Interactive, not autonomous.** Ask the user what happens at each step. They know the demo narrative; you help build and document it.
- **Build incrementally.** Don't script ahead of what we've discussed and agreed on.
- **Code chapters need real validation.** Deploy to hardware, check logs, verify it works before documenting.
- **The script is a presenter reference**, not a word-for-word teleprompter. Keep entries concise: what to do, what to say (key phrases), what the audience sees.

## Context files

- `script.md` — The presenter script being built
- `CLAUDE.md` — "Script Progress" section tracks current position
- `project_spec.md` — Chapter map with completion status
- `chapters/` — Built chapter code
- Auto-memory at `~/.claude/projects/*/memory/MEMORY.md` — Project learnings

## Hardware notes

Read from CLAUDE.md "Demo Hardware" section for current hardware setup and any substitutions in play.
