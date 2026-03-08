# Building a Subset Frame System

How to build a reduced frame system containing only specific components,
for use with armplanning.PlanMotion.

## When to use

When you have multiple arms or many components on the machine but only want
to plan for one arm. A full frame system causes the planner to check
collisions against all components, which can:
- Slow down planning significantly
- Block valid paths due to cross-arm collision checks

By building a subset frame system, you give the planner only what it needs.

## The pattern

```go
func buildArmFrameSystem(
	ctx context.Context,
	rfs framesystem.Service,
	armName string,
) (*referenceframe.FrameSystem, error) {
	fsCfg, err := rfs.FrameSystemConfig(ctx)
	if err != nil {
		return nil, fmt.Errorf("getting frame system config: %w", err)
	}

	// Filter to only include the arm's parts
	var armParts []*referenceframe.FrameSystemPart
	for _, part := range fsCfg.Parts {
		if part.FrameConfig.Name() == armName {
			armParts = append(armParts, part)
		}
	}

	fs, err := referenceframe.NewFrameSystem("planner", armParts, nil)
	if err != nil {
		return nil, fmt.Errorf("building frame system: %w", err)
	}
	return fs, nil
}
```

## Including multiple components

If you need the arm plus its gripper (e.g., for collision geometry):

```go
wanted := map[string]bool{
	conf.ArmName:     true,
	conf.GripperName: true,
}

var parts []*referenceframe.FrameSystemPart
for _, part := range fsCfg.Parts {
	if wanted[part.FrameConfig.Name()] {
		parts = append(parts, part)
	}
}
```

## Adding supplemental transforms

If you need extra frames (like a tool attached to the gripper) that
aren't in the machine's config:

```go
extraFrames := []*referenceframe.LinkInFrame{
	referenceframe.NewLinkInFrame(
		"my_gripper",                                        // parent frame
		spatialmath.NewPose(r3.Vector{Z: 100}, nil),         // offset from parent
		"bottle_top",                                         // name of new frame
		nil,                                                  // geometry (optional)
	),
}

fs, err := referenceframe.NewFrameSystem("planner", parts, extraFrames)
```

## Why this matters

On a machine with multiple arms, a full frame system causes the planner
to check collisions between all of them. This slows planning and can
block valid paths. A subset frame system keeps planning fast and avoids
false collision hits from unrelated components.
