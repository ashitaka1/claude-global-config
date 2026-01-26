---
name: reload
description: Hot-reload a viam module for a machine by its main partID
argument-hint: <part-id>
---

Rebuild and hot-reload the module to part ID: $ARGUMENTS

```bash
# Clean old build artifacts
rm -f module.tar.gz bin/*

# Use viam module reload-local (triggers build via meta.json)
viam module reload-local --part-id $ARGUMENTS
```