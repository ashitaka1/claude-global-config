# Project Specification Template

> This template helps you define project requirements, architecture, and development approach. Delete sections that aren't relevant to your project.

## Purpose
*1-2 sentences: What problem does this project solve?*

## User Profile
*Who will use this? What are their goals?*

1. Primary user type
2. Secondary user type (if applicable)

## Goals

**Goal:** *Specific, measurable outcome*
**Goal:** *Another specific outcome*

**Non-Goal:** *Explicitly out of scope*
**Non-Goal:** *Another explicit exclusion*

*Budget/Timeline:* [Optional - if relevant]

## Features

### Required
- Feature that must be delivered
- Another must-have feature
- Core functionality

### Milestones

*Break work into phases if the project is complex:*

1. ✅/⏳ Milestone 1: Description
2. ⏳ Milestone 2: Description
3. ⏳ Milestone 3: Description

### Nice-to-Have
- Feature if time permits
- Enhancement that improves UX

### Bonus Round
- Advanced features beyond initial scope
- Optimizations or polish

## Tech Stack

### Language(s)
- Primary language and version
- Secondary languages (if any)

### Frameworks/Libraries
- Key dependencies
- Why chosen

### Platform/Deployment
- Where does this run?
- Deployment model

### Infrastructure (if applicable)
- Databases
- APIs
- Cloud services
- Hardware

## Technical Architecture

### Components
*Describe major parts of the system and how they interact:*

- **Component 1**: Purpose and responsibilities
- **Component 2**: Purpose and responsibilities
- **Integration points**: How components communicate

### Data Schema (if applicable)

**Data types:**
- Type 1: Description
- Type 2: Description

**Relationships:**
- How data relates across the system

### Configuration Variables (if applicable)
*Settings that may vary between deployments or use cases:*

- `variable_name`: Purpose and expected values
- `another_var`: Purpose and expected values

## Documentation Strategy

*If this project produces documentation (README, guides, etc.), describe the approach:*

### README Target Outline
1. Section 1 - Content
2. Section 2 - Content
3. Section 3 - Content

### Additional Documentation
- API documentation approach
- User guides
- Developer guides

## Milestone Architecture Decisions

*As you reach milestones, document key architectural decisions here:*

### Milestone N: [Title]

**Approach:** Brief summary of the approach chosen

**Key Decisions:**
- Decision 1 and rationale
- Decision 2 and rationale

**Trade-offs considered:**
- Alternative A: Why not chosen
- Alternative B: Why not chosen

## Implementation Notes

*Accumulate learnings as you build. This is a decision log for patterns, gotchas, and discoveries:*

- Pattern/technique discovered and why it was used
- Integration detail that wasn't obvious
- Workaround for a limitation
- Design choice that worked well

## Development Process

*Define how development will proceed:*

**Testing approach:**
- Unit test strategy
- Integration test strategy
- Manual testing steps

**Code review:**
- Review requirements (if team project)
- Approval process

**Deployment:**
- How code reaches production/users
- Rollback strategy (if applicable)

---

## Usage Notes

**For Claude:** This file provides project context. Reference it when making architectural decisions, writing documentation, or implementing features. Keep it updated as the project evolves.

**Sections to delete if not needed:**
- Milestones (for small projects)
- Data Schema (if no data model)
- Configuration Variables (if no configuration)
- Documentation Strategy (if minimal docs)
- Bonus Round (if no stretch goals)
