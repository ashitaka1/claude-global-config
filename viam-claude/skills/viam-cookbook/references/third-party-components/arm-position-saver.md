# Arm Position Saver (Switch API)

How to use `erh:vmodutils:arm-position-saver` to save and recall arm joint positions
via the Switch component API.

## When to use

When you need to teach an arm a pose interactively (physically move it, then save),
and later move back to that exact pose. This is useful for setting named positions
without manually reading and transcribing joint values.

## What this is

A third-party module (`erh:vmodutils:arm-position-saver`) that repurposes the
`rdk:component:switch` API for arm pose management. It is NOT a physical switch —
the switch positions map to operations on an arm.

## Configuration

```json
{
  "model": "erh:vmodutils:arm-position-saver",
  "api": "rdk:component:switch",
  "name": "my-pose-saver",
  "attributes": {
    "arm": "my-arm",
    "motion": "",
    "joints": [0.0, -1.57, 0.0, -1.57, 0.0, 0.0]
  }
}
```

### Attributes

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `arm` | string | yes | Name of the arm component to control |
| `motion` | string | no | `""` (empty) for direct joint move; `"builtin"` for motion-planned move |
| `joints` | array of floats | no | Saved joint positions in radians. Initially empty; populated by SetPosition(1). |

## API mapping

The switch API has two methods: `SetPosition` and `GetPosition`. This module
maps integer switch positions to arm operations:

### SetPosition

| Position | Effect | Destructive? |
|----------|--------|-------------|
| `0` | No-op. Does nothing. | No |
| `1` | **SAVES the arm's current joint positions into the machine config.** Overwrites the `joints` array. **There is no undo.** | **YES** |
| `2` | Moves the arm to the saved joint positions. Uses direct joint move or motion planning depending on `motion` attribute. | No (but moves the arm) |

### GetPosition

| Return value | Meaning |
|-------------|---------|
| `0` | Arm is NOT at the saved pose |
| `1` | Arm IS at the saved pose |

## Usage from any SDK

Since this uses the standard Switch API, any Viam SDK client can control it.

### Python

```python
from viam.components.switch import Switch

pose_saver = Switch.from_robot(robot, "my-pose-saver")

# Check if arm is at the saved pose
pos = await pose_saver.get_position()
print(f"At saved pose: {pos == 1}")

# Move arm to saved pose
await pose_saver.set_position(2)

# DANGER: Save current arm position (overwrites config permanently)
await pose_saver.set_position(1)
```

### Go

```go
import "go.viam.com/rdk/components/switch"

saver, err := switch.FromRobot(robot, "my-pose-saver")

// Check if arm is at the saved pose
pos, err := saver.GetPosition(ctx, nil)
// pos == 0 means not at pose, pos == 1 means at pose

// Move arm to saved pose
err = saver.SetPosition(ctx, 2, nil)

// DANGER: Save current arm position (overwrites config permanently)
err = saver.SetPosition(ctx, 1, nil)
```

### TypeScript

```typescript
const saver = Switch.fromRobot(robot, "my-pose-saver");

// Check if arm is at the saved pose
const pos = await saver.getPosition();

// Move arm to saved pose
await saver.setPosition(2);

// DANGER: Save current arm position (overwrites config permanently)
await saver.setPosition(1);
```

## Typical workflow

1. Physically move the arm (or jog it via the Builder UI) to the desired pose.
2. Call `SetPosition(1)` to save. The `joints` array in the machine config updates.
3. Move the arm elsewhere.
4. Call `SetPosition(2)` to return to the saved pose.
5. Call `GetPosition()` to confirm arrival (returns 1 when at pose).

## Critical warnings

- **SetPosition(1) is destructive and permanent.** It writes the arm's current
  joint positions into the machine configuration, overwriting whatever was in the
  `joints` array. There is no undo, no confirmation prompt, no history.

- **Do not confuse position numbers.** Position 1 saves (destructive), position 2
  moves. Getting them backwards will overwrite your saved pose instead of moving to it.

- **The `joints` array is in radians.** If you pre-populate it manually, use radians
  not degrees.

- **Motion attribute matters.** With `motion: ""`, the arm does a direct joint move
  (fastest, no collision avoidance). With `motion: "builtin"`, the motion service
  plans a path (slower, collision-aware). For teach-pendant style use, direct is
  usually fine.

## Pitfalls

- Calling `SetPosition(1)` during a demo or presentation will silently overwrite
  your carefully tuned pose. Only call it when you genuinely want to re-teach.
- The component appears in the Builder UI as a switch, which can be confusing.
  The toggle/slider UI may map to SetPosition calls — be careful clicking around
  in the UI if you have unsaved work in the joints config.
- If `joints` is empty or missing and you call `SetPosition(2)`, behavior depends
  on the module implementation — it may error or move to zeros. Save a pose first.
