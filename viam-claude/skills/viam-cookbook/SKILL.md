---
name: viam-cookbook
description: >
  Practical reference for building Viam modules and applications in Go.
  Contains tested recipes with real code for module development, motion planning,
  spatial math, and frame systems. Use this skill whenever working on Viam Go SDK
  code — especially for modules, arm motion, pose computation, DoCommand patterns,
  dependency resolution, or armplanning. Even if the user doesn't mention "cookbook"
  or "recipe," consult this when you're about to write Viam Go code so you use the
  correct SDK patterns rather than guessing from docs.
---

# Viam Cookbook

A collection of tested recipes for building Viam modules and applications in Go.
These recipes come from real, working codebases — not theoretical examples.

## When to use this

Consult the index below whenever you need to:
- Build a Viam module (config, validation, constructor, DoCommand)
- Move an arm or plan motion
- Work with poses, orientations, or frames
- Resolve dependencies in a module
- Use armplanning.PlanMotion for plan-then-execute workflows

## Recipe Index

### Module Development
| Recipe | File | What it covers |
|--------|------|----------------|
| Generic Service Module | `references/module-development/generic-service.md` | Full module pattern: Config, Validate, constructor, DoCommand routing, Close |
| Dependency Resolution | `references/module-development/dependency-resolution.md` | FromProvider, FromDependencies, declaring deps in Validate, implicit vs explicit deps |

### Motion
| Recipe | File | What it covers |
|--------|------|----------------|
| Plan-Then-Execute | `references/motion/plan-then-execute.md` | armplanning.PlanMotion for pre-validation, then MoveToJointPositions for execution |
| Motion Service Move | `references/motion/motion-service-move.md` | motion.Move for combined plan+execute, MoveReq, PoseInFrame destinations |

### Spatial Math
| Recipe | File | What it covers |
|--------|------|----------------|
| Frame-Relative Poses | `references/spatial-math/frame-relative-poses.md` | Working in component frames to simplify geometry, letting the frame system do transforms |
| Orientation Vectors | `references/spatial-math/orientation-vectors.md` | How OV works in Viam, computing aim directions, OrientationVector vs OrientationVectorDegrees |
| Spatialmath Utilities | `references/spatial-math/spatialmath-utilities.md` | Compose, PoseBetween, Interpolate, PoseAlmostEqual, and other pose utilities |

### Frame System
| Recipe | File | What it covers |
|--------|------|----------------|
| Accessing the Frame System | `references/frame-system/accessing-frame-system.md` | framesystem.FromDependencies, FrameSystemConfig, NewFrameSystem |
| Building a Subset Frame System | `references/frame-system/building-subset.md` | Filtering FrameSystemParts for armplanning with reduced collision checking |

### Third-Party Components
| Recipe | File | What it covers |
|--------|------|----------------|
| Arm Position Saver (Switch API) | `references/third-party-components/arm-position-saver.md` | erh:vmodutils:arm-position-saver — save/recall arm poses via Switch API; destructive SetPosition(1) gotcha |

## How to use

1. Find the relevant recipe in the index above
2. Read the referenced file for the full pattern with code
3. Adapt the code to your use case

Each recipe contains:
- A brief explanation of when and why to use the pattern
- Complete, working Go code from real modules
- Key imports needed
- Common pitfalls to avoid
