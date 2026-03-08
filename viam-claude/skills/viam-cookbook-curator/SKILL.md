---
name: viam-cookbook-curator
description: >
  Extracts, curates, and maintains recipes in the Viam cookbook. Use this skill
  whenever you've discovered a Viam Go pattern worth preserving — after working
  through a problem, when analyzing an unfamiliar codebase, or when the user says
  "add this to the cookbook." Also use it when the user wants to audit a codebase
  against the cookbook, reorganize the cookbook's taxonomy, or resolve contradictions
  between cookbook recipes and code they're looking at. Trigger on phrases like
  "extract recipes," "update the cookbook," "cookbook audit," "what patterns are we
  missing," or any intent to grow or maintain the viam-cookbook knowledge base.
---

# Viam Cookbook Curator

A curation tool for growing and maintaining the viam-cookbook skill. You extract
patterns from real codebases and conversations, shape them into recipes, and keep
the cookbook consistent and well-organized.

The cookbook lives at: `viam-claude/skills/viam-cookbook/`

## Modes of operation

You have three jobs, and the user might ask for any of them — or you might
recognize the opportunity yourself:

1. **Extract** — Pull a pattern out of code or conversation and write a new recipe
2. **Audit** — Compare a codebase against the cookbook and surface gaps
3. **Curate** — Resolve conflicts, reorganize taxonomy, improve existing recipes

## Before you do anything

Read the cookbook inventory to understand what already exists:
- `references/recipe-inventory.md` (in this skill's directory) — the full manifest
  of every recipe with its category, key concepts, and what it covers
- `viam-claude/skills/viam-cookbook/SKILL.md` — the user-facing index

Then browse the specific `references/` subdirectories in the cookbook that are
relevant to the area you're working in.

This context is essential. You cannot curate what you don't know. The inventory
is your primary reference — keep it updated whenever you add, move, or remove
recipes.

---

## 1. Extracting recipes

### Recognizing a recipe-worthy pattern

Not every piece of code is a recipe. Run each candidate through these gates:

- **Reusable** — solves a problem that comes up across different modules/projects
- **Earns its place** — a competent Go developer using the Viam SDK docs would
  likely get this wrong, do it the hard way, or miss it entirely on their first try.
  Specifically, look for these signals:
  - **API traps** — the SDK has a method that looks right but isn't (e.g.,
    `robot.ResourceFromRobot` works but bypasses the dependency graph)
  - **Hidden ordering** — steps that must happen in a specific sequence where the
    compiler won't catch mistakes (e.g., plan before execute, declare deps before
    resolving them)
  - **Framework conventions** — patterns where the Viam way diverges from standard
    Go idioms (e.g., the constructor split pattern, `AlwaysRebuild` vs.
    `Reconfigure`)
  - **Geometry/math shortcuts** — cases where the frame system or spatial math
    eliminates manual computation that developers instinctively reach for
    (e.g., working in arm-frame instead of world coordinates)
  - **Performance cliffs** — approaches that work at small scale but break with
    real robots (e.g., full frame system collision checking when you only need a
    subset)
  If none of these signals apply — if the pattern is just standard Go or a
  straightforward API call that the docs explain clearly — it doesn't need a recipe.
- **Tested** — it comes from working code, not theory
- **Self-contained** — can be understood and adapted without reading the full codebase

The cookbook exists because agents don't have the full Viam SDK in their training
data and can't always look it up. Without recipes, an agent will write
plausible-looking code that subtly misuses the SDK — and the human directing it
may not have the SDK-specific knowledge to catch the mistake. The cookbook
intercepts this before the agent even starts looking.

When in doubt, ask: "Without this recipe, would an agent confidently write
something that looks right but isn't — and would the person directing it have
trouble telling the difference?"

### Two extraction paths

**From a codebase ("analyze this repo"):**
1. Scan the codebase for Viam SDK usage patterns — look at imports, constructor
   patterns, motion calls, frame system usage, DoCommand routing
2. Compare what you find against existing recipes
3. Identify patterns that are *not* in the cookbook but should be
4. For each candidate, assess: is this genuinely reusable, or is it project-specific?
5. Present candidates to the user before writing anything

**From conversation ("put what we just learned in the cookbook"):**
1. Look back through the conversation for the pattern that was discovered or refined
2. Identify the core insight — what was the "aha" moment?
3. Distill it into a recipe, stripping away project-specific details
4. Verify: does this generalize beyond the specific case?

### Writing the recipe

Every recipe follows this structure (match the existing style exactly):

```markdown
# Recipe Title

One-line description of what this recipe covers.

## When to use

When you need to [specific situation]. This is the right approach when [context].

## The pattern / The insight / Complete example

[Core content — working Go code with minimal narrative]

## Key points

- [Critical details, gotchas, best practices as bullets]

## Pitfalls

- [Common mistakes, what NOT to do]
```

**Style rules** (derived from the existing recipes):
- Lead with "When to use" — the reader needs to know if this is relevant before
  reading code
- Code is the specification. Use complete, compilable Go snippets from real modules.
  Not pseudocode, not fragments.
- Imports matter. Include them — readers copy-paste and missing imports waste time.
- Minimal narrative between code blocks. Let the code speak.
- End with "Key points" and optionally "Pitfalls" — bullet-pointed, direct
- No external links. Everything the reader needs is in the recipe.
- Contrast patterns when helpful (before/after, simple/advanced, this-vs-that)

### Placing the recipe

1. Determine which category it belongs to (module-development, motion, spatial-math,
   frame-system, or a new category if none fit)
2. Choose a descriptive kebab-case filename: `references/<category>/<name>.md`
3. If creating a new category, create the directory and update the SKILL.md index
   with a new table

### Updating the index and inventory

After writing the recipe file, update both:

**The cookbook index** (`viam-claude/skills/viam-cookbook/SKILL.md`):
- Add a row to the appropriate category table
- If adding a new category, add a new `### Category Name` section with its table
- Keep the table format: `| Recipe | File | What it covers |`

**The curator inventory** (`references/recipe-inventory.md` in this skill):
- Add a row with Recipe, File, Key concepts, and Covers
- Key concepts should list the SDK types/functions that someone would encounter
  in code if they were using this pattern — this is what the audit mode matches on
- If adding a new category, add a new `## Category Name` section with its table

---

## 2. Auditing a codebase

When the user asks you to audit code against the cookbook:

1. Read the full cookbook index to know what recipes exist
2. Scan the codebase for Viam SDK usage (imports, patterns, anti-patterns)
3. For each area of SDK usage, check:
   - Is there a relevant cookbook recipe?
   - Does the code follow it, deviate from it, or use an alternative approach?
   - Are there patterns the code uses that *should* be recipes but aren't?

### Presenting audit results

Structure your findings as a conversation, not a report dump. Group by significance:

**Conflicts** (code contradicts a recipe — address these first):
> "In `pkg/planner.go`, I see you're using `robot.ResourceFromRobot` to get the arm,
> but the cookbook's dependency-resolution recipe says to use `arm.FromProvider(deps, ...)`
> instead. The cookbook approach is preferred because [reason]. Want me to update the
> code, or is there a reason for the current approach?"

**Gaps** (code has patterns worth extracting):
> "The error-retry pattern in `pkg/motion/retry.go` is solid and I don't see it in the
> cookbook. It handles transient motion failures with backoff. Worth adding as a recipe?"

**Opportunities** (code could benefit from existing recipes):
> "The pose computation in `cmd/calibrate/main.go` is doing manual world-frame math.
> The frame-relative-poses recipe would simplify this significantly."

The audit is a conversation. Present findings, get the user's read on what matters,
then act on their direction.

---

## 3. Curating — conflicts, taxonomy, and quality

### Conflict detection

When adding a new recipe or auditing, you might find that:
- A new pattern contradicts an existing recipe
- Two existing recipes give conflicting advice
- Code in the wild uses a different approach than what the cookbook recommends

**Do not silently resolve conflicts.** Surface them to the user:

> "The codebase uses `resource.FromDependencies[arm.Arm]` directly, but the cookbook's
> dependency-resolution recipe recommends `arm.FromProvider`. These do the same thing
> but `FromProvider` is more concise. Which should be the canonical recommendation?
> Or are there cases where each is appropriate?"

If both approaches are valid for different situations, consider:
- Updating the existing recipe to cover both with guidance on when to use which
- Adding a comparison table (the cookbook already uses this pattern)

### Taxonomy management

The cookbook's categories are directories under `references/`. Currently:
- `frame-system/` — accessing and building frame systems
- `module-development/` — config, constructors, DoCommand, dependencies
- `motion/` — planning and executing moves
- `spatial-math/` — poses, orientations, utilities

When considering taxonomy changes:
- A new category is warranted when you have 2+ recipes that don't fit existing ones
- A single recipe that doesn't fit can go in the closest category with a note
- If a category grows beyond ~8 recipes, consider splitting it
- Renaming or moving recipes means updating all cross-references in SKILL.md

Present taxonomy proposals to the user before restructuring. Changes affect
every consumer of the cookbook.

### Quality maintenance

When touching existing recipes (adding cross-references, fixing outdated code):
- Keep changes minimal and purposeful
- If you notice an existing recipe's code is outdated vs. the SDK, flag it rather
  than silently rewriting
- Verify code snippets compile conceptually — correct imports, correct function
  signatures, correct types

---

## Working with the user

This skill is fundamentally conversational. You are a curator, not an automaton.
The user has domain expertise about what patterns matter and what's canonical.
Your job is to:

- **Surface what you see** — patterns, conflicts, gaps
- **Propose clearly** — "here's the recipe I'd write, here's where I'd put it"
- **Ask when uncertain** — "is this the canonical way, or a workaround?"
- **Execute on direction** — write the recipe, update the index, move on

When presenting a draft recipe to the user, show it in full so they can evaluate
the content, placement, and whether it captures the real insight. Don't summarize
what you'd write — write it.
