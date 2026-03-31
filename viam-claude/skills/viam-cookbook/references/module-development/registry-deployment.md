# Module Registry Deployment

How to create, configure, and publish a Viam module to the registry.

## When to use

When creating a new module or publishing an existing local-only module to the
Viam registry.

## Creating a new module

`viam module generate` scaffolds a complete module: Makefile, meta.json,
deploy workflow, and entry point. It accepts flags for non-interactive use.

The resource type (component vs. service) is inferred from the subtype — there
is no `--resource-type` flag.

**Generate and register in one step** (requires `viam login`):

```bash
viam module generate \
  --name my-module \
  --language go \
  --visibility public \
  --public-namespace mynamespace \
  --resource-subtype sensor \
  --model-name my-sensor \
  --register
```

**Generate local-only** (no authentication needed):

```bash
viam module generate \
  --name my-module \
  --language go \
  --resource-subtype sensor \
  --model-name my-sensor
```

With `--register`, the module is created in the Viam registry during generation,
associated with your org. Without it, the module is local-only — see "Migrating
to the registry" below to publish later.

## Post-generation fixups

`viam module generate` produces a working scaffold, but several `meta.json`
fields need attention before your first cloud build will succeed.

| Field | Generator default | What to fix |
|-------|------------------|-------------|
| `url` | `""` (empty) | **Set to your GitHub repo URL.** Cloud build fails without this: _"Meta.json must have a url field set in order to start a cloud build."_ |
| `description` | Generic placeholder (e.g., `"Modular generic service: controller-complete"`) | Replace with a meaningful description. This is searchable in the registry — include what the module does, protocols, hardware it supports. |
| `markdown_link` | `"README.md"` | Viam renders this file on the module's registry page. The default is fine if you have a `README.md` at the repo root. Can also be a URL. |
| `models` | Not included | Add a `models` array listing every API/model pair the module registers (see below). Without this, the registry page won't show what models the module provides. |
| `build.arch` | Includes `windows/amd64` | Remove platforms you don't target. Extra entries cause unnecessary build failures. |

Fix these before tagging your first release. The typical sequence is:

```bash
# 1. Generate the module
viam module generate --name my-module ... --register

# 2. Create the GitHub repo
gh repo create my-module --private --source=. --push

# 3. Fix meta.json: url, description, models, build.arch
# 4. Commit and push the fix
# 5. Add GitHub Actions secrets (viam_key_id, viam_key_value)
# 6. Tag and push to trigger cloud build
git tag 0.1.0 && git push origin 0.1.0
```

## meta.json reference

The registry and cloud build system are driven by `meta.json`. Key fields:

| Field | What it does |
|-------|-------------|
| `module_id` | Registry identifier: `namespace:module-name`. Must match what's registered. |
| `visibility` | `public`, `public_unlisted`, or `private` |
| `description` | Searchable description — include chip, protocol, capabilities |
| `url` | GitHub repo URL. **Required for cloud build** — build action needs this to fetch source. |
| `markdown_link` | Path to README rendered on the registry page (relative path or URL) |
| `entrypoint` | Path to the executable inside the archive — must exist and be +x |
| `models` | Array of API/model pairs the module provides (see below) |
| `build.build` | Command cloud build runs per target arch (e.g., `make module.tar.gz`) |
| `build.setup` | Command run once per build environment (e.g., `make setup`) |
| `build.path` | Archive path the build system uploads |
| `build.arch` | Target platforms — cloud build iterates this list |

### The models field

```json
"models": [
  {
    "api": "rdk:component:sensor",
    "model": "avery:nfc:pn532"
  }
]
```

`module_id` (`namespace:module-name`) identifies the deployable package.
The model triplet (`namespace:family:model`) identifies the resource it provides.
These are independent — a single module can register multiple models.

## Migrating from local-only to registry

1. **Prepare `meta.json`:** Fill in `module_id`, `visibility`, `description`,
   `url`, `models`, and `build.arch` (only platforms you test).

2. **Register the module name:**
   ```bash
   viam module create --name=my-module --public-namespace=mynamespace
   ```
   This must happen before the first cloud build. The build action runs
   `viam module update` which fails if the module doesn't exist yet.

3. **Add GitHub Actions secrets:** `viam_key_id` and `viam_key_value`
   (org-level API key) in repo Settings > Secrets and variables > Actions.

4. **Tag and push:**
   ```bash
   git tag v0.1.0
   git push origin v0.1.0
   ```
   The `.github/workflows/deploy.yml` (generated with the module) triggers
   automatically and builds for each arch in `meta.json`.

## Key points

- `viam module create` overwrites `meta.json` — back up customizations before
  running it, then re-apply.
- `viam module update` pushes metadata changes to the registry without building.
  Run it after editing `meta.json` fields like `description` or `visibility`.
- Machines auto-update to the latest module version. Pin a specific version in
  machine config to prevent this.

## Pitfalls

- **`url` is empty after generation.** This is the most common first-build failure.
  The generator leaves `"url": ""` — set it to the GitHub repo URL before tagging.
- **Register before tagging.** The cloud build runs `viam module update` first,
  which fails if the module doesn't exist in the registry.
- **`module_id` must match your registered namespace.** Mismatches cause upload
  failures.
- **`models` array is not generated.** The generator doesn't add it. Without it,
  the registry page won't list your module's models. Add it manually.
- **`description` is a throwaway placeholder.** The generator fills it with
  something like `"Modular generic service: my-model"`. Replace it — this is
  how users find your module in the registry.
- **`generic` is not a valid subtype.** Use `generic-service`
  (`rdk:service:generic`) or `generic-component` (`rdk:component:generic`).
  The CLI won't error clearly — it just generates wrong boilerplate.
