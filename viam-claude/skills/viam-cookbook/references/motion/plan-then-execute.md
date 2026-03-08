# Plan-Then-Execute with armplanning.PlanMotion

How to pre-validate arm moves by planning offline, then execute the planned
joint positions directly.

## When to use

When you need to validate that a sequence of arm moves is feasible BEFORE
moving the arm. This is critical for multi-step workflows where you don't
want the arm stranded at position 5 of 12 because position 6 is unreachable.

The key distinction:
- `motion.Service.Move()` — plans AND executes in one call. No way to inspect
  the plan or bail before moving.
- `armplanning.PlanMotion()` — plans ONLY. Returns a trajectory of joint
  positions. You inspect it, validate it, then execute separately.

## Imports

```go
import (
	"go.viam.com/rdk/motionplan/armplanning"
	"go.viam.com/rdk/referenceframe"
	"go.viam.com/rdk/spatialmath"
)
```

## The pattern

### 1. Get the frame system and current joint positions

```go
// Get frame system config and build a FrameSystem for planning
fsCfg, err := s.rfs.FrameSystemConfig(ctx)
// ... filter parts if needed (see frame-system/building-subset.md) ...
fs, err := referenceframe.NewFrameSystem("my-planner", parts, nil)

// Get current arm joints as the starting state
startJoints, err := s.arm.JointPositions(ctx, nil)
```

### 2. Plan each move

```go
goalPose := referenceframe.NewPoseInFrame(armName, targetPose)

req := &armplanning.PlanRequest{
	FrameSystem: fs,
	Goals: []*armplanning.PlanState{
		armplanning.NewPlanState(
			referenceframe.FrameSystemPoses{armName: goalPose},
			nil,
		),
	},
	StartState: armplanning.NewPlanState(nil, referenceframe.FrameSystemInputs{
		armName: startJoints,
	}),
}

plan, _, err := armplanning.PlanMotion(ctx, logger, req)
if err != nil {
	// Move is infeasible — bail before touching the arm
	return fmt.Errorf("plan failed: %w", err)
}

// Extract the goal joint positions from the trajectory
traj := plan.Trajectory()
goalJoints := traj[len(traj)-1][armName]
```

### 3. Chain plans sequentially

Feed each plan's end joints as the next plan's start:

```go
allJoints := [][]referenceframe.Input{startJoints}

for i, pose := range targetPoses {
	goalPose := referenceframe.NewPoseInFrame(armName, pose)
	req := &armplanning.PlanRequest{
		FrameSystem: fs,
		Goals: []*armplanning.PlanState{
			armplanning.NewPlanState(
				referenceframe.FrameSystemPoses{armName: goalPose}, nil,
			),
		},
		StartState: armplanning.NewPlanState(nil, referenceframe.FrameSystemInputs{
			armName: allJoints[len(allJoints)-1], // previous end = next start
		}),
	}

	plan, _, err := armplanning.PlanMotion(ctx, logger, req)
	if err != nil {
		return fmt.Errorf("plan failed for position %d: %w", i, err)
	}

	traj := plan.Trajectory()
	allJoints = append(allJoints, traj[len(traj)-1][armName])
}
```

### 4. Execute the pre-planned joints

```go
for i := 1; i < len(allJoints); i++ {
	err := arm.MoveToJointPositions(ctx, allJoints[i], nil)
	if err != nil {
		return fmt.Errorf("move to position %d failed: %w", i, err)
	}
}
```

Or for smooth continuous motion through all positions:
```go
err := arm.MoveThroughJointPositions(ctx, allJoints[1:], nil, nil)
```

## L2 distance check with retry

The motion planner is nondeterministic — it may find a valid but wildly
different joint configuration (e.g., flipping the elbow). Use
`referenceframe.InputsL2Distance` to detect this and replan:

```go
const maxTries = 5

for try := 1; try <= maxTries; try++ {
	plan, _, err := armplanning.PlanMotion(ctx, logger, req)
	if err != nil {
		return fmt.Errorf("plan failed: %w", err)
	}

	goalJoints := plan.Trajectory()[len(plan.Trajectory())-1][armName]
	d := referenceframe.InputsL2Distance(startJoints, goalJoints)
	logger.Infof("[try %d] InputsL2Distance: %v", try, d)

	if d > 1.3 {
		// Plan found a valid but distant configuration — try again
		if try < maxTries {
			logger.Warnf("[try %d] L2 too high, replanning...", try)
			continue
		}
		// Save debug data on final failure
		if writeErr := req.WriteToFile("/tmp/bad-plan.json"); writeErr != nil {
			logger.Errorf("failed to write debug: %v", writeErr)
		}
		return fmt.Errorf("joint distance too large after %d tries: %v", maxTries, d)
	}

	// Plan is good — use these joints
	err = arm.MoveToJointPositions(ctx, goalJoints, nil)
	if err != nil {
		continue // retry on execution failure too
	}
	break
}
```

This catches cases where the planner finds elbow-flip solutions that
would crash the arm into the table or other obstacles.

## Saving debug data

If a plan looks suspicious, serialize the request for offline debugging:

```go
if err := req.WriteToFile("/tmp/bad-plan.json"); err != nil {
	logger.Errorf("failed to write debug: %v", err)
}
```

The saved JSON includes the frame system, goals, and start state —
everything needed to reproduce the plan offline.

## Putting it all together

A typical multi-step sweep would:
1. Compute target poses in the arm's frame
2. Plan all moves via PlanMotion, collecting joint positions
3. Bail with an error if any plan fails (arm hasn't moved yet)
4. Execute pre-planned joints sequentially, performing work at each stop
