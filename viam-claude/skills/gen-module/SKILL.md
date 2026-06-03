---
name: gen-module
description: Generate a new Viam module with the specified configuration. Use to initialize a repository with viam module boilerplate.
argument-hint: <module-name> <language> <visibility> <namespace> <subtype> <model-name> [--register]
---

Generate a new Viam module with these parameters: $ARGUMENTS

For example: `mycorp-sensor go public myorg sensor mycorp-sensor --register`

**Valid subtypes:** `sensor`, `camera`, `motor`, `arm`, `movement_sensor`, `vision`,
`generic-component`, `generic-service`, etc. The subtype also fixes whether the module is a
component or a service — for a generic resource, choose `generic-component`
(`rdk:component:generic`) or `generic-service` (`rdk:service:generic`).

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

**Generate local-only** (no `viam login` needed, but `--public-namespace` is still required):

```bash
viam module generate \
  --name MODULE_NAME \
  --language LANGUAGE \
  --public-namespace NAMESPACE \
  --resource-subtype SUBTYPE \
  --model-name MODEL_NAME
```

Run the command yourself — supplying every input as a flag makes it non-interactive, so
execute it directly rather than asking the user to. Two requirements to watch:

- **`--public-namespace` is required even for local-only generation.** Without all of
  `--name`, `--language`, `--public-namespace`, `--resource-subtype`, and `--model-name`,
  the command fails with `missing required flags for non-interactive mode`.
- **`--register` requires being logged in first** (`viam login`); otherwise it fails with
  `authentication required`.

After generation:
1. Move generated files from subdirectory to project root if needed
2. Run `go mod tidy`
3. Run tests: `go test ./...`
