---
name: gen-module
description: Generate a new Viam module with the specified configuration. Use to initialize a repository with viam module boilerplate.
argument-hint: <module-name> <namespace> <subtype> <model-name>
---

Generate a new Viam module with these parameters: $ARGUMENTS

For example: `mycorp-sensor myorg rdk:component:sensor mycorp-sensor`

```bash
viam module generate \
  --language go \
  --name MODULE_NAME \
  --public-namespace NAMESPACE \
  --model-name MODEL_NAME \
  --resource-subtype SUBTYPE \
  --visibility private
```

After generation:
1. Move generated files from subdirectory to project root if needed
2. Run `go mod tidy`
3. Run tests: `go test ./...`