---
name: logs
description: View recent machine logs from Viam. Use when you need to check for the effect of a new change, debug a problem, or validate something is working on a viam host.
argument-hint: <machine-id> [keyword]
---

View recent machine logs for the machine-id and optional keywoard found in $ARGUMENTS

For example: `abc-123` or `abc-123 error`

```bash
# If no keyword provided:
viam machine logs --machine MACHINE_ID --count 50

# If keyword provided:
viam machine logs --machine MACHINE_ID --count 50 --keyword KEYWORD
```