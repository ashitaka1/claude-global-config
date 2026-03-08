# Spatialmath Utilities

Reference for the pose manipulation functions in `go.viam.com/rdk/spatialmath`.

## Import

```go
import "go.viam.com/rdk/spatialmath"
```

## Pose constructors

```go
spatialmath.NewPose(point r3.Vector, o Orientation) Pose
spatialmath.NewPoseFromPoint(point r3.Vector) Pose        // identity orientation
spatialmath.NewPoseFromOrientation(o Orientation) Pose     // origin position
spatialmath.NewZeroPose() Pose                             // origin + identity
spatialmath.NewPoseFromProtobuf(pos *commonpb.Pose) Pose   // from protobuf
spatialmath.NewPoseFromDH(a, d, alpha float64) Pose        // Denavit-Hartenberg
```

## Pose composition and transformation

```go
// Compose: C(x) = A(B(x)). Chain two transforms.
result := spatialmath.Compose(poseA, poseB)

// PoseBetween: the transform FROM a TO b. If you apply this to a, you get b.
delta := spatialmath.PoseBetween(poseA, poseB)

// PoseInverse: the inverse transform.
inv := spatialmath.PoseInverse(pose)

// PoseDelta: difference between two poses (similar to PoseBetween).
diff := spatialmath.PoseDelta(poseA, poseB)
```

### When to use which

- **Compose**: "I have a base pose and a relative offset — give me the combined pose"
- **PoseBetween**: "What transform takes me from pose A to pose B?"
- **PoseInverse**: "Reverse this transform"

## Interpolation

```go
// Interpolate between two poses. by=0.0 returns p1, by=1.0 returns p2.
mid := spatialmath.Interpolate(p1, p2, 0.5)
```

Useful for creating smooth intermediate waypoints between two poses.

## Pose comparison

```go
// Are these poses approximately equal? (default epsilon)
spatialmath.PoseAlmostEqual(a, b) bool

// With custom epsilon
spatialmath.PoseAlmostEqualEps(a, b, epsilon) bool

// Same position, ignoring orientation?
spatialmath.PoseAlmostCoincident(a, b) bool
spatialmath.PoseAlmostCoincidentEps(a, b, epsilon) bool
```

## Orientation utilities

```go
// Identity orientation (no rotation)
spatialmath.NewZeroOrientation() Orientation

// Relative orientation between two orientations
spatialmath.OrientationBetween(o1, o2) Orientation

// Inverse orientation
spatialmath.OrientationInverse(o) Orientation

// Approximate equality
spatialmath.OrientationAlmostEqual(o1, o2) bool
spatialmath.OrientationAlmostEqualEps(o1, o2, epsilon) bool
```

## Conversion

```go
// Pose to protobuf (for gRPC)
spatialmath.PoseToProtobuf(p) *commonpb.Pose

// Pose to map (for JSON/logging)
m, err := spatialmath.PoseMap(p)
```

## Point transformation

```go
// Transform a point by a quaternion rotation + translation
spatialmath.TransformPoint(quaternion, translation, point) r3.Vector
```

## The Pose interface

```go
type Pose interface {
	Point() r3.Vector
	Orientation() Orientation
}
```

Every pose gives you a position (`Point()`) and an orientation. The
orientation can be converted to any representation:
`OrientationVectorRadians()`, `OrientationVectorDegrees()`, `Quaternion()`,
`AxisAngles()`, `EulerAngles()`, `RotationMatrix()`.
