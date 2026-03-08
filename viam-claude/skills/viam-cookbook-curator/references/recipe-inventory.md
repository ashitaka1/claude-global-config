# Recipe Inventory

Complete manifest of every recipe in the viam-cookbook. Update this file whenever
you add, move, rename, or remove a recipe.

## How to read this

Each entry lists:
- **Recipe** — the display name used in the cookbook index
- **File** — path relative to `viam-claude/skills/viam-cookbook/`
- **Key concepts** — SDK types, functions, or ideas central to the recipe (for
  matching against code you're analyzing)
- **Covers** — what the recipe teaches

---

## Module Development

| Recipe | File | Key concepts | Covers |
|--------|------|-------------|--------|
| Generic Service Module | `references/module-development/generic-service.md` | `resource.RegisterService`, `generic.API`, `resource.NativeConfig`, `AlwaysRebuild`, `DoCommand` | Full module lifecycle: model registration, Config struct with JSON tags, Validate returning deps, constructor split (registered + exported), DoCommand key-based routing, Close with cancel |
| Dependency Resolution | `references/module-development/dependency-resolution.md` | `arm.FromProvider`, `framesystem.FromDependencies`, `resource.FromDependencies`, `Config.Validate` | Declaring deps in Validate, resolving typed resources from Dependencies map, implicit deps (motion service, frame system), component vs. service vs. generic helpers |

## Motion

| Recipe | File | Key concepts | Covers |
|--------|------|-------------|--------|
| Plan-Then-Execute | `references/motion/plan-then-execute.md` | `armplanning.PlanMotion`, `MoveToJointPositions`, `PlanRequest`, `NewFrameSystem` | Pre-validating moves by planning offline, chaining plans (end joints → next start), L2 distance for elbow-flip detection, debug data |
| Motion Service Move | `references/motion/motion-service-move.md` | `motion.Move`, `MoveReq`, `PoseInFrame` | One-shot combined plan-and-execute, MoveReq fields, world-frame vs. component-relative destinations |

## Spatial Math

| Recipe | File | Key concepts | Covers |
|--------|------|-------------|--------|
| Frame-Relative Poses | `references/spatial-math/frame-relative-poses.md` | `NewPoseInFrame`, `NewZeroPose`, arm-frame Z-axis convention | Working in component frames to simplify geometry, Z=aim direction / XY=perpendicular plane, before/after contrast |
| Orientation Vectors | `references/spatial-math/orientation-vectors.md` | `OrientationVector`, `OrientationVectorDegrees`, OX/OY/OZ/Theta | OV representation (aim direction + roll), common orientations, computing aim from vector subtraction, converting between orientation types |
| Spatialmath Utilities | `references/spatial-math/spatialmath-utilities.md` | `Compose`, `PoseBetween`, `PoseInverse`, `Interpolate`, `PoseAlmostEqual` | Pose constructors, composition/transformation, interpolation, comparison, when-to-use-which |

## Frame System

| Recipe | File | Key concepts | Covers |
|--------|------|-------------|--------|
| Accessing the Frame System | `references/frame-system/accessing-frame-system.md` | `framesystem.FromDependencies`, `FrameSystemConfig`, `GetPose`, `TransformPose` | Retrieving frame system service, getting component poses in different frames, building a FrameSystem object |
| Building a Subset Frame System | `references/frame-system/building-subset.md` | `FrameSystemParts`, supplemental transforms, collision filtering | Filtering components for reduced frame systems, adding tool transforms, performance benefits |
