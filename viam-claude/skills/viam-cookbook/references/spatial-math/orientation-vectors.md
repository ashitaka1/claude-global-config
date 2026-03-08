# Orientation Vectors

How Viam represents orientation and how to compute aim directions.

## The OrientationVector

Viam uses a custom orientation representation called `OrientationVector` (OV).
It has four fields:

```go
type OrientationVector struct {
	Theta float64 `json:"th"` // rotation around the aim axis (radians)
	OX    float64 `json:"x"`  // X component of the aim direction
	OY    float64 `json:"y"`  // Y component of the aim direction
	OZ    float64 `json:"z"`  // Z component of the aim direction
}
```

- **(OX, OY, OZ)** defines the direction the end-effector's Z-axis points —
  think of it as "which way the tool/camera is facing"
- **Theta** is the rotation around that aim axis (the "roll")

There's also `OrientationVectorDegrees` where Theta is in degrees instead
of radians. Protobuf/JSON Poses use degrees.

## Common orientations

```go
// Pointing along +Z (straight ahead/down depending on arm config)
ov := &spatialmath.OrientationVector{OX: 0, OY: 0, OZ: 1}

// Pointing along -Z (opposite direction)
ov := &spatialmath.OrientationVector{OX: 0, OY: 0, OZ: -1}

// Pointing along +X
ov := &spatialmath.OrientationVector{OX: 1, OY: 0, OZ: 0}
```

## Computing an aim direction

To make the arm point FROM a position TOWARD a target:

```go
pos := r3.Vector{X: 100, Y: 50, Z: 0}      // where the arm is
target := r3.Vector{X: 0, Y: 0, Z: 500}     // where to aim

dir := target.Sub(pos).Normalize()

orientation := &spatialmath.OrientationVector{
	OX: dir.X,
	OY: dir.Y,
	OZ: dir.Z,
}
```

This is just vector subtraction + normalization. No rotation matrices needed.

## Reading orientation from a pose

```go
pose, err := arm.EndPosition(ctx, nil)

// Get as OrientationVector (radians)
ov := pose.Orientation().OrientationVectorRadians()

// Get as OrientationVectorDegrees
ovd := pose.Orientation().OrientationVectorDegrees()

// The aim axis as a vector
aimDir := r3.Vector{X: ov.OX, Y: ov.OY, Z: ov.OZ}
```

## Creating poses with orientation

```go
import (
	"github.com/golang/geo/r3"
	"go.viam.com/rdk/spatialmath"
)

// Pose with position and orientation (radians)
pose := spatialmath.NewPose(
	r3.Vector{X: 100, Y: 200, Z: 300},
	&spatialmath.OrientationVector{OX: 0, OY: 0, OZ: 1, Theta: 0},
)

// Pose with position and orientation (degrees) — used in protobuf
pose := spatialmath.NewPose(
	r3.Vector{X: 100, Y: 200, Z: 300},
	&spatialmath.OrientationVectorDegrees{OX: 0, OY: 0, OZ: 1, Theta: 0},
)

// Position only (identity orientation)
pose := spatialmath.NewPoseFromPoint(r3.Vector{X: 100, Y: 200, Z: 300})

// Identity (origin, no rotation)
pose := spatialmath.NewZeroPose()
```

## The Orientation interface

`Orientation` is an interface. OV is one representation. You can convert between
representations:

```go
o := pose.Orientation()
o.OrientationVectorRadians()  // -> *OrientationVector
o.OrientationVectorDegrees()  // -> *OrientationVectorDegrees
o.Quaternion()                // -> quat.Number
o.AxisAngles()                // -> *R4AA
o.EulerAngles()               // -> *EulerAngles
o.RotationMatrix()            // -> *RotationMatrix
```

## Key points

- OV is Viam-specific. It's not Euler angles, quaternions, or axis-angle —
  it's a "point the Z-axis this way, then roll by Theta" representation.
- (OX, OY, OZ) does NOT need to be normalized — the SDK normalizes internally.
  But it's good practice to normalize for clarity.
- When computing aim directions between two points, it's just vector
  subtraction. This is the main advantage of OV — aim directions are intuitive
  coordinate math.
