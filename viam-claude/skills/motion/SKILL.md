---
name: motion
description: Move a robot arm by pose. Supports get-pose, set-pose (absolute), and move-delta (relative offset). Use when the user wants to move an arm, check its position, or nudge it in a direction.
argument-hint: <get|set|delta> <component> [x y z ox oy oz theta]
---

# Motion Skill

Move a robot arm via the Viam motion service. Requires a part ID — resolve it from `viam-cli-data` if not provided.

## Resolve machine context

Use the `viam-cli-data` skill to look up the part ID for the target machine. The user may specify a machine by name or role; resolve it to a `--part <part-id>` flag.

## Parse $ARGUMENTS

The first word is the subcommand: `get`, `set`, or `delta`. The second word is the component name. Remaining arguments are pose values.

Flexible natural-language input is expected. Examples:

```
/motion get arm1
/motion set arm1 z 300
/motion delta arm1 z -50
/motion delta arm1 x 10 y -20
/motion get arm1 on dev_machine
```

If the user says things like "move arm1 down 50mm", interpret as `delta arm1 z -50`. Directions map to axes: up/down = +/-z, left/right = +/-x (or +/-y depending on frame — ask if ambiguous), forward/back = +/-y (or +/-x — ask if ambiguous).

## Subcommands

### get — Get current pose

```bash
viam machine part motion get-pose --part <part-id> --component <component>
```

Print the result clearly with labeled axes.

### set — Set absolute pose

Replace specific coordinates, leaving others unchanged (this is how `set-pose` already works — it gets current pose and only overwrites specified values).

```bash
viam machine part motion set-pose --part <part-id> --component <component> [--x <val>] [--y <val>] [--z <val>] [--ox <val>] [--oy <val>] [--oz <val>] [--theta <val>]
```

Only pass the flags the user specified.

### delta — Move relative to current pose

This requires two steps:

1. Get current pose:
   ```bash
   viam machine part motion get-pose --part <part-id> --component <component>
   ```

2. Parse the returned pose values, add the requested deltas, then call set-pose with the new absolute values:
   ```bash
   viam machine part motion set-pose --part <part-id> --component <component> --x <new_x> --y <new_y> --z <new_z> --ox <new_ox> --oy <new_oy> --oz <new_oz> --theta <new_theta>
   ```

Always show the user the current pose, the delta being applied, and the target pose before executing the move.

## Output format

After any command, display the pose in a readable table:

```
   X:  100.00   Y:  200.00   Z:  300.00
  OX:    0.00  OY:    0.00  OZ:    1.00  Theta:  0.00
```

For delta moves, show before and after.

## Notes

- Orientation values (OX, OY, OZ, Theta) use orientation vector degrees format. OX/OY/OZ define the rotation axis, Theta is the rotation angle in degrees.
- The pose is in the world reference frame.
- Units are millimeters for position, degrees for theta.
