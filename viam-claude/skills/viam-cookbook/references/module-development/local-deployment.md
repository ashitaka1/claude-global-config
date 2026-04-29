# Local Module Deployment

How to deploy a module under development to a Viam host without going through
the registry.

## When to use

When you want to run an unpublished or in-progress module on a real machine:

- Module was generated locally (without `--register`) and hasn't been published
- Module is registered but you want to test changes before tagging a release
- One-off patching of a registry module on a single machine for debugging

For published modules using the cloud build pipeline, see **Registry Deployment**.

## The pattern

`viam module reload-local` handles the entire deploy from the module's source
directory:

1. Builds the tarball via `meta.json`'s `build.build` command (e.g., `make module.tar.gz`)
2. Uploads the tarball to the target part
3. Patches the part's machine config to add a `local` module entry pointing at
   the uploaded path
4. Restarts viam-server on the part so the new module is loaded

```bash
# Find the part ID for the target machine (main part = first listed)
viam machines part list --machine-id <MACHINE_ID>

# Deploy from the module's source directory
cd /path/to/my-module
viam module reload-local --part-id <PART_ID>
```

Subsequent iterations are the same single command.

## First-time setup: add a component instance

`reload-local` makes the module's models available on the part, but instances
still need explicit component (or service) config. Add this in the Viam app or
via a config patch:

```json
{
  "components": [
    {
      "name": "my-sensor",
      "type": "sensor",
      "model": "myorg:my-module:my-sensor",
      "attributes": { }
    }
  ]
}
```

The `model` string must match a triplet from `meta.json`'s `models` array exactly.

## Iteration loop

After editing source:

```bash
viam module reload-local --part-id <PART_ID>
```

viam-server restarts the module process and the component instance picks up
the new code.

## Cross-architecture fallback (build on target)

Modules set up for cloud build have Makefiles that pass
`GOOS=$(VIAM_BUILD_OS) GOARCH=$(VIAM_BUILD_ARCH)` to `go build`. This is correct
for cloud build but breaks when `reload-local` invokes it locally with a target
that requires CGO cross-compilation — common when developing on macOS targeting
Linux, because `go.viam.com/rdk` pulls in `pion/mediadevices`.

When that fails, build on the target machine and upload the existing tarball:

```bash
# 1. Copy source to target (exclude .git, build artifacts)
tar czf /tmp/module-src.tar.gz \
  --exclude='.git' --exclude='bin' --exclude='module.tar.gz' .
scp /tmp/module-src.tar.gz <target>:/tmp/module-src.tar.gz

# 2. Build on target
ssh <target> 'mkdir -p /tmp/module-build \
  && cd /tmp/module-build \
  && tar xzf /tmp/module-src.tar.gz \
  && make module.tar.gz'

# 3. Copy tarball back
scp <target>:/tmp/module-build/module.tar.gz ./module.tar.gz

# 4. Upload without rebuilding
viam module reload-local --no-build --part-id <PART_ID>
```

`--no-build` skips the local build step and uploads the existing
`module.tar.gz` directly. The Makefile's `GOOS`/`GOARCH` variables are empty
when not set by cloud build, so building natively on the target produces the
correct binary without any Makefile changes.

**Don't modify the Makefile to "fix" cross-compilation.** It's correct for
cloud build. The issue is `reload-local` reusing that build step in a context
where cross-compilation isn't viable.

## Prerequisites

The module must have a working `meta.json` with at minimum:

- `models` — array declaring at least one `{api, model}` pair
- `build.build` — command that produces `build.path` (default: `make module.tar.gz`)
- `build.path` — path to the archive the CLI uploads
- `entrypoint` — path to the executable inside the archive

`viam module generate` produces all of these. See **Registry Deployment** for
the full `meta.json` reference.

## Key points

- **No registration required.** `reload-local` works whether or not the module
  exists in the registry. The part config gets a `local` module entry, not a
  registry reference, so unregistered modules deploy identically to registered ones.
- **Per-part deployment.** `reload-local` targets one part at a time. There's
  no propagation to other machines — that's what registry publishing is for.
- **No version history.** Each `reload-local` overwrites the previous tarball
  on the part. Roll back by redeploying older source.
- **`viam login` required** so the CLI can authenticate against your org's machines.

## Pitfalls

- **Forgetting the component config.** A successful `reload-local` with no
  working component usually means there's no config entry for the model.
  Registering the module is necessary but not sufficient.
- **Mismatched `model` strings.** The component's `model` field must match a
  `meta.json` triplet exactly. viam-server won't surface a clear error for typos —
  the component just fails to come up.
- **Modifying the Makefile to fix cross-compile errors.** See the cross-arch
  fallback section. The Makefile is correct; use `--no-build` instead.
- **Go must be installed on the target** for the cross-arch fallback. If it
  isn't, use a Docker container with matching OS/arch.
- **macOS tar adds xattr metadata** that produces harmless warnings on Linux
  during the cross-arch build (`Ignoring unknown extended header keyword
  'LIBARCHIVE.xattr.com.apple.provenance'`). Safe to ignore.
- **Running from the wrong directory.** `reload-local` reads `meta.json` from
  the current working directory. Run it from the module's source root.
