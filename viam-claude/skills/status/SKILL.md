---
name: status
description: Get current machine status and component health from Viam. Use when you want machine status including component states (STATE_READY, STATE_UNHEALTHY, etc.) and any error messages.
argument-hint: <part-id>
---

Check machine status and component health for part: $ARGUMENTS

```bash
viam machine part run --part $ARGUMENTS \
  --method 'viam.robot.v1.RobotService.GetMachineStatus' \
  --data '{}'
```