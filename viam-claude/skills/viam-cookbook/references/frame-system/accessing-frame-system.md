# Accessing the Frame System

How to get the robot's frame system from within a module.

## When to use

When you need the frame system to:
- Build a `FrameSystem` for `armplanning.PlanMotion`
- Get poses of components relative to each other
- Transform poses between frames

## Getting the frame system service

The frame system is an implicit service on every Viam machine. Access it
via `framesystem.FromDependencies`:

```go
import "go.viam.com/rdk/robot/framesystem"

rfs, err := framesystem.FromDependencies(deps)
```

No name is needed — there's only one frame system per machine.

## Using the frame system service

The `framesystem.Service` interface provides:

```go
type Service interface {
	resource.Resource

	// Get the config (parts that make up the frame system)
	FrameSystemConfig(ctx context.Context) (*Config, error)

	// Get pose of a component in a destination frame
	GetPose(ctx context.Context, componentName, destinationFrame string,
		supplementalTransforms []*referenceframe.LinkInFrame,
		extra map[string]interface{}) (*referenceframe.PoseInFrame, error)

	// Transform a pose from one frame to another
	TransformPose(ctx context.Context, pose *referenceframe.PoseInFrame,
		dst string, supplementalTransforms []*referenceframe.LinkInFrame,
	) (*referenceframe.PoseInFrame, error)

	// Get current joint positions of all components
	CurrentInputs(ctx context.Context) (referenceframe.FrameSystemInputs, error)
}
```

## Building a FrameSystem object for armplanning

`armplanning.PlanMotion` needs a `*referenceframe.FrameSystem`, not the service.
Build one from the config:

```go
fsCfg, err := rfs.FrameSystemConfig(ctx)
if err != nil {
	return err
}

fs, err := referenceframe.NewFrameSystem("my-planner", fsCfg.Parts, nil)
if err != nil {
	return err
}
```

The third argument to `NewFrameSystem` is supplemental transforms (usually nil).

## Getting component poses

```go
// Where is the arm's end-effector in the world frame?
pose, err := rfs.GetPose(ctx, "my_arm", "world", nil, nil)

// Where is the arm relative to the camera?
pose, err := rfs.GetPose(ctx, "my_arm", "my_camera", nil, nil)
```

## Key points

- The frame system is always available — every machine has one
- `FrameSystemConfig` returns `*Config` with a `Parts` field
  (`[]*referenceframe.FrameSystemPart`)
- You can filter parts before building a FrameSystem to create a subset
  (see building-subset.md)
