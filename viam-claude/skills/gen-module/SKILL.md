---
name: gen-module
description: Generate a new Viam module with the specified configuration. Use to initialize a repository with viam module boilerplate.
argument-hint: <module-name> <language> <visibility> <namespace> <resource-type> <subtype> <model-name>
---

Generate a new Viam module with these parameters: $ARGUMENTS

For example: `mycorp-sensor myorg component sensor mycorp-sensor`

```bash
viam module generate \
  --name MODULE_NAME \
  --language LANGUAGE \
  --visibility VISIBILITY \
  --public-namespace NAMESPACE \
  --resource-type RESOURCE_TYPE \
  --resource-subtype SUBTYPE \
  --model-name MODEL_NAME \
```

Horrifyingly, there is a TTY requirement for this cli, so even though providing all those arguments means you don't need interactive mode, claude code cannot sucessfully execute that command. So instead, output:

"Here's the command to generate the module:
COMMAND
Please tell me when you've finished running that."

After generation:
1. Move generated files from subdirectory to project root if needed
2. Run `go mod tidy`
3. Run tests: `go test ./...`
