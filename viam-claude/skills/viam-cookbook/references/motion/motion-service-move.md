# Motion Service Move

How to use the builtin motion service for combined plan-and-execute arm moves.

## When to use

When you want a simple one-shot move and don't need to inspect the plan
before executing. Good for single moves, not ideal for multi-step sequences
where you need pre-validation (use plan-then-execute.md instead).

## Imports

```go
import (
	"go.viam.com/rdk/referenceframe"
	"go.viam.com/rdk/services/motion"
	"go.viam.com/rdk/spatialmath"
)
```

## Basic move

```go
// Get the motion service
mot, err := motion.FromProvider(deps, "builtin")

// Define destination as a PoseInFrame
// The frame name determines the coordinate system
dest := referenceframe.NewPoseInFrame("world",
	spatialmath.NewPose(
		r3.Vector{X: 100, Y: 200, Z: 300},
		&spatialmath.OrientationVectorDegrees{OX: 0, OY: 0, OZ: 1, Theta: 0},
	),
)

// Move — this blocks until the arm reaches the destination
moved, err := mot.Move(ctx, motion.MoveReq{
	ComponentName: "my_arm",
	Destination:   dest,
})
```

## MoveReq fields

```go
type MoveReq struct {
	ComponentName string                        // Name of the component to move
	Destination   *referenceframe.PoseInFrame   // Goal pose in a named frame
	WorldState    *referenceframe.WorldState     // Obstacles and transforms (optional)
	Constraints   *motionplan.Constraints        // Motion constraints (optional)
	Extra         map[string]interface{}          // Extra parameters (optional)
}
```

## Moving in different frames

The `PoseInFrame` frame name controls the coordinate system:

```go
// Move relative to world origin
dest := referenceframe.NewPoseInFrame("world", pose)

// Move relative to the arm's own frame (end-effector frame)
// This is powerful — the motion service handles the transform
dest := referenceframe.NewPoseInFrame("my_arm", relativePose)
```

## Key points

- `Move` both plans AND executes — there's no way to inspect the plan first
- `Move` blocks until the arm reaches the destination or an error occurs
- `ComponentName` is a string (the component's name), not a `resource.Name`
- For pre-validated multi-step moves, use `armplanning.PlanMotion` instead
  (see plan-then-execute.md)
