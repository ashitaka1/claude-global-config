# Generic Service Module

How to build a Viam module that implements the generic service API with DoCommand routing.

## When to use

When you need a module that exposes custom commands via `DoCommand` rather than
implementing a specific component API (arm, sensor, etc.). This is the right choice
for orchestration services, calibration tools, or anything that coordinates
multiple components.

## The pattern

A generic service module has these parts:
1. Model registration in `init()`
2. A `Config` struct with JSON tags
3. `Validate` returning required/optional dependency names
4. A constructor that resolves dependencies from the `Dependencies` map
5. `DoCommand` that routes to handler methods
6. `Close` for cleanup

## Complete example

A service that orchestrates arm movement and calibration data collection.

```go
package mymodule

import (
	"context"
	"fmt"

	"go.viam.com/rdk/components/arm"
	"go.viam.com/rdk/logging"
	"go.viam.com/rdk/resource"
	"go.viam.com/rdk/robot/framesystem"
	"go.viam.com/rdk/services/generic"
)

// Model triplet: namespace:module-name:model-name
var MyModel = resource.NewModel("myorg", "my-module", "my-model")

func init() {
	resource.RegisterService(generic.API, MyModel,
		resource.Registration[resource.Resource, *Config]{
			Constructor: newMyService,
		},
	)
}

// Config fields must be exported with json tags.
type Config struct {
	ArmName        string  `json:"arm_name"`
	HelperService  string  `json:"helper_service"`
	DistanceMM     float64 `json:"distance_mm"`
}

// Validate returns (required_deps, optional_deps, error).
// Required deps are resource names that must exist on the machine.
func (cfg *Config) Validate(path string) ([]string, []string, error) {
	if cfg.ArmName == "" {
		return nil, nil, resource.NewConfigValidationFieldRequiredError(path, "arm_name")
	}
	if cfg.HelperService == "" {
		return nil, nil, resource.NewConfigValidationFieldRequiredError(path, "helper_service")
	}
	if cfg.DistanceMM <= 0 {
		return nil, nil, fmt.Errorf("%s: distance_mm must be positive", path)
	}

	deps := []string{
		cfg.ArmName,
		cfg.HelperService,
	}
	return deps, nil, nil
}

type myService struct {
	resource.AlwaysRebuild // Recreate on every config change

	name      resource.Name
	logger    logging.Logger
	cfg       *Config
	arm       arm.Arm
	rfs       framesystem.Service
	helperSvc resource.Resource

	cancelCtx context.Context
	cancelFn  func()
}

// The registered constructor — extracts typed config, delegates to exported constructor.
func newMyService(
	ctx context.Context,
	deps resource.Dependencies,
	rawConf resource.Config,
	logger logging.Logger,
) (resource.Resource, error) {
	conf, err := resource.NativeConfig[*Config](rawConf)
	if err != nil {
		return nil, err
	}
	return NewMyService(ctx, deps, rawConf.ResourceName(), conf, logger)
}

// Exported constructor — useful for testing without the full resource framework.
func NewMyService(
	ctx context.Context,
	deps resource.Dependencies,
	name resource.Name,
	conf *Config,
	logger logging.Logger,
) (resource.Resource, error) {
	a, err := arm.FromProvider(deps, conf.ArmName)
	if err != nil {
		return nil, fmt.Errorf("arm %q: %w", conf.ArmName, err)
	}

	rfs, err := framesystem.FromDependencies(deps)
	if err != nil {
		return nil, fmt.Errorf("frame system: %w", err)
	}

	helperSvc, err := resource.FromDependencies[resource.Resource](
		deps, generic.Named(conf.HelperService),
	)
	if err != nil {
		return nil, fmt.Errorf("helper service %q: %w", conf.HelperService, err)
	}

	cancelCtx, cancelFn := context.WithCancel(context.Background())
	return &myService{
		name: name, logger: logger, cfg: conf,
		arm: a, rfs: rfs, helperSvc: helperSvc,
		cancelCtx: cancelCtx, cancelFn: cancelFn,
	}, nil
}

func (s *myService) Name() resource.Name { return s.name }

// DoCommand routes commands by checking for known keys.
func (s *myService) DoCommand(
	ctx context.Context, cmd map[string]interface{},
) (map[string]interface{}, error) {
	if _, ok := cmd["start"]; ok {
		return s.handleStart(ctx)
	}
	if _, ok := cmd["status"]; ok {
		return s.handleStatus(ctx)
	}
	return nil, fmt.Errorf("unknown command, expected start or status")
}

func (s *myService) Close(context.Context) error {
	s.cancelFn()
	return nil
}
```

## Key points

- `resource.AlwaysRebuild` means every config change destroys and recreates the
  service. Fine for tools that aren't long-running.
- Split the constructor into a registered one (takes `resource.Config`) and an
  exported one (takes typed `*Config`). The exported one is easier to test.
- DoCommand pattern: check for known keys in the map, route to methods. Return
  `map[string]interface{}` for the response.
- Always call `cancelFn()` in `Close()`.

## Pitfalls

- Do NOT use `robot.ResourceFromRobot` in modules. Always use `FromProvider` or
  `FromDependencies` with the `deps` map.
- Validate must return dependency names as strings. The framework uses these to
  build the dependency graph and pass the right resources to your constructor.
