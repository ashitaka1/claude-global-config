# Dependency Resolution

How to declare, resolve, and use dependencies in Viam Go modules.

## When to use

Every module that needs access to other components or services on the machine.

## How it works

1. `Config.Validate()` returns string slices of required and optional dependency names
2. The framework resolves those names and passes them as `resource.Dependencies` to your constructor
3. Your constructor uses typed helpers to extract the resources you need

## Declaring dependencies in Validate

```go
func (cfg *Config) Validate(path string) ([]string, []string, error) {
	// Required deps — constructor will fail if these don't exist
	deps := []string{
		cfg.ArmName,
		cfg.CalibrationService,
	}

	// Optional deps — nil if not present, constructor should handle gracefully
	optionals := []string{}
	if cfg.CupFinderService != "" {
		optionals = append(optionals, cfg.CupFinderService)
	}

	return deps, optionals, nil
}
```

## Resolving typed resources from Dependencies

Use the `FromProvider` or `FromDependencies` helpers. Each component/service
package provides its own typed helper.

```go
import (
	"go.viam.com/rdk/components/arm"
	"go.viam.com/rdk/components/camera"
	"go.viam.com/rdk/components/gripper"
	"go.viam.com/rdk/resource"
	"go.viam.com/rdk/robot/framesystem"
	"go.viam.com/rdk/services/generic"
	"go.viam.com/rdk/services/motion"
	"go.viam.com/rdk/services/vision"
)

// Typed component helpers — preferred approach
a, err := arm.FromProvider(deps, conf.ArmName)
cam, err := camera.FromProvider(deps, conf.CameraName)
g, err := gripper.FromProvider(deps, conf.GripperName)

// Typed service helpers
mot, err := motion.FromProvider(deps, "builtin")
vis, err := vision.FromProvider(deps, conf.VisionServiceName)

// Frame system — special case, no name needed
rfs, err := framesystem.FromDependencies(deps)

// Generic resource (for DoCommand-only access to another service)
calSvc, err := resource.FromDependencies[resource.Resource](
	deps, generic.Named(conf.CalibrationService),
)
```

## Implicit dependencies

Some resources are always available on the machine and don't need to be
declared in Validate:

- **Motion service** (`"builtin"`): Always present. Access via
  `motion.FromProvider(deps, "builtin")`. You still need to declare it if
  you want it in your deps map — add `motion.Named("builtin").String()`.
- **Frame system**: Always present. Access via `framesystem.FromDependencies(deps)`.

Whether you need to explicitly declare these depends on whether the framework
passes them to your constructor. In practice, it's safer to declare them.

To explicitly declare motion as a dependency:
```go
deps := []string{motion.Named("builtin").String()}
// ... add other deps ...
return deps, optionals, nil
```

## Calling DoCommand on another service

When you have a generic `resource.Resource` reference to another service,
call `DoCommand` to invoke its custom commands:

```go
// Save calibration position on the frame-calibration service
_, err := s.calSvc.DoCommand(ctx, map[string]interface{}{
	"save_calibration_position": true,
})

// Check tags — returns a result map
result, err := s.calSvc.DoCommand(ctx, map[string]interface{}{
	"check_tags": true,
})
```

## Large dependency sets

For modules with many dependencies, extract resolution into a helper function
that returns a components struct:

```go
type Components struct {
	Arm     arm.Arm
	Gripper gripper.Gripper
	Cam     camera.Camera
	Motion  motion.Service
	Rfs     framesystem.Service
}

func ComponentsFromDependencies(config *Config, deps resource.Dependencies) (*Components, error) {
	var err error
	c := &Components{}

	c.Arm, err = arm.FromDependencies(deps, config.ArmName)
	if err != nil {
		return nil, err
	}

	c.Motion, err = motion.FromDependencies(deps, "builtin")
	if err != nil {
		return nil, err
	}

	c.Rfs, err = framesystem.FromDependencies(deps)
	if err != nil {
		return nil, err
	}

	// ... more deps ...
	return c, nil
}
```

## Pitfalls

- `FromProvider` is preferred over `FromDependencies` (which is deprecated
  but still works). Both do the same thing.
- Never use `robot.ResourceFromRobot` in a module — you don't have access
  to the robot. Dependencies come from the `deps` map.
- If you forget to declare a dependency in Validate, it won't be in the deps
  map and FromProvider will fail at construction time.
