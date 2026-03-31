# Local Module Reload (Cross-Architecture)

How to hot-reload a module onto a remote machine when local cross-compilation
fails — the common case for macOS-to-Linux development.

## When to use

When you're developing a module on macOS and your target machine runs Linux.
Modules set up for cloud build have Makefiles that use `VIAM_BUILD_OS` /
`VIAM_BUILD_ARCH` — `reload-local` sets these to the target platform, triggering
cross-compilation. This fails when the dependency tree includes CGO packages
(common via `go.viam.com/rdk`, which pulls in `pion/mediadevices`).

## The problem

`viam module reload-local --part-id <ID>` runs the Makefile build step locally
before uploading. The generated Makefile passes `GOOS=$(VIAM_BUILD_OS)
GOARCH=$(VIAM_BUILD_ARCH)` to `go build`, which is correct for cloud build
(where the build environment matches the target) but fails on a macOS dev
machine targeting linux:

```bash
# This fails on macOS → linux when CGO deps exist
viam module reload-local --part-id <PART_ID>
# Error: pion/mediadevices — undefined: malgo.AllocatedContext ...
```

## The pattern

Build on the target machine (or a machine with matching OS/arch), copy the
artifact back, then reload with `--no-build`:

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

## Key points

- `--no-build` skips the local build step and uploads the existing
  `module.tar.gz` directly. This is the key flag.
- The Makefile's `GOOS`/`GOARCH` variables are empty when not set by the cloud
  build environment, so building natively on the target produces the correct
  binary without any Makefile changes.
- Keep the Makefile as-is for cloud build compatibility. Do not add
  `CGO_ENABLED=0` or remove the `GOOS`/`GOARCH` passthrough — cloud build
  depends on them.

## Pitfalls

- **Don't modify the Makefile to "fix" cross-compilation.** The Makefile is
  correct for cloud build. The issue is that `reload-local` reuses the same
  build step in a context where cross-compilation isn't viable.
- **Go must be installed on the target.** If it isn't, use a Docker container
  with matching OS/arch, or a CI-like environment.
- **macOS tar adds xattr metadata** that produces harmless warnings on Linux
  (`Ignoring unknown extended header keyword 'LIBARCHIVE.xattr.com.apple.provenance'`).
  These are safe to ignore.
