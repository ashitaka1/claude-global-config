---
name: gen-module
description: Generate a new Viam module with the specified configuration. Use to initialize a repository with viam module boilerplate.
argument-hint: <module-name> <language> <visibility> <namespace> <subtype> <model-name> [--register]
---

Generate a new Viam module with these parameters: $ARGUMENTS

For example: `mycorp-sensor go public myorg sensor mycorp-sensor --register`

**Valid subtypes:** `sensor`, `camera`, `motor`, `arm`, `movement_sensor`, `vision`,
`generic-component`, `generic-service`, etc. **`generic` is not a valid subtype** —
you must specify `generic-component` (`rdk:component:generic`) or `generic-service`
(`rdk:service:generic`).

**Generate and register** (requires `viam login`):

```bash
viam module generate \
  --name MODULE_NAME \
  --language LANGUAGE \
  --visibility VISIBILITY \
  --public-namespace NAMESPACE \
  --resource-subtype SUBTYPE \
  --model-name MODEL_NAME \
  --register
```

**Generate local-only** (no authentication needed):

```bash
viam module generate \
  --name MODULE_NAME \
  --language LANGUAGE \
  --resource-subtype SUBTYPE \
  --model-name MODEL_NAME
```

The resource type (component vs. service) is inferred from the subtype — there is no `--resource-type` flag.

Horrifyingly, there is a TTY requirement for this cli, so even though providing all those arguments means you don't need interactive mode, claude code cannot successfully execute that command. So instead, output:

"Here's the command to generate the module:
COMMAND
Please tell me when you've finished running that."

After generation:
1. Move generated files from subdirectory to project root if needed
2. Run `go mod tidy`
3. Run tests: `go test ./...`
