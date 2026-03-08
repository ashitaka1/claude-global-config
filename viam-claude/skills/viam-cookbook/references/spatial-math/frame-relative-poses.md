# Frame-Relative Poses

How to simplify geometry by working in a component's own frame of reference
instead of world coordinates.

## When to use

Whenever you're computing poses relative to a component (especially an arm's
end-effector). Working in the component's frame eliminates manual coordinate
transforms — the frame system does it for you.

## The insight

In Viam, an arm's end-effector has a local coordinate system where:
- **Z axis** = the direction the arm is pointing (the OrientationVector direction)
- **X, Y axes** = the plane perpendicular to the arm's aim

This means if you express your geometry in the arm's frame:
- A point "ahead" of the arm is simply `(0, 0, distance)` along Z
- A circle perpendicular to the arm's aim is on the XY plane: `(r*cos, r*sin, 0)`
- No need to compute orthonormal bases or manual rotations

## Example: computing positions on a circle

Without frame-relative poses (world coordinates — complex):
```go
// Need the arm's current pose, orientation, orthonormal basis...
p := currentPose.Point()
ov := currentPose.Orientation().OrientationVectorRadians()
aimAxis := r3.Vector{X: ov.OX, Y: ov.OY, Z: ov.OZ}.Normalize()
u, v := orthonormalBasis(aimAxis)  // custom function needed!
pos := r3.Vector{
	X: p.X + radius*(cos*u.X + sin*v.X),
	Y: p.Y + radius*(cos*u.Y + sin*v.Y),
	Z: p.Z + radius*(cos*u.Z + sin*v.Z),
}
```

With frame-relative poses (arm's frame — simple):
```go
// Circle is on XY plane by definition. No basis computation needed.
pos := r3.Vector{X: radius * math.Cos(angle), Y: radius * math.Sin(angle), Z: 0}
target := r3.Vector{X: 0, Y: 0, Z: distance}
dir := target.Sub(pos).Normalize()
orientation := &spatialmath.OrientationVector{OX: dir.X, OY: dir.Y, OZ: dir.Z}
pose := spatialmath.NewPose(pos, orientation)
```

Then when you use this pose as a motion destination, wrap it in the arm's frame:
```go
dest := referenceframe.NewPoseInFrame(armName, pose)
```

The motion service / planner handles the frame transform automatically.

## Complete example: cone sweep positions

```go
func computeConePositions(distanceMM, radiusMM float64, n int) []spatialmath.Pose {
	poses := make([]spatialmath.Pose, 0, n+1)
	poses = append(poses, spatialmath.NewZeroPose()) // initial position

	target := r3.Vector{X: 0, Y: 0, Z: distanceMM}

	for i := range n {
		angle := 2 * math.Pi * float64(i) / float64(n)
		x := radiusMM * math.Cos(angle)
		y := radiusMM * math.Sin(angle)

		pos := r3.Vector{X: x, Y: y, Z: 0}
		dir := target.Sub(pos).Normalize()
		orientation := &spatialmath.OrientationVector{
			OX: dir.X, OY: dir.Y, OZ: dir.Z,
		}

		poses = append(poses, spatialmath.NewPose(pos, orientation))
	}
	return poses
}
```

All positions are relative to the arm's current pose. No need to read
EndPosition or do any world-frame math.

## Key points

- `NewPoseInFrame(componentName, pose)` tells the motion system to interpret
  the pose relative to that component's frame
- `NewZeroPose()` = identity = "stay where you are" in the component's frame
- This pattern makes geometry self-evident and testable without needing a
  real arm or frame system
