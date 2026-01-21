# Viam Platform Best Practices Guide

This guide consolidates common patterns, CLI commands, and development practices for the Viam robotics platform.

---

## Table of Contents

1. [Viam CLI Patterns](#viam-cli-patterns)
2. [Go Module Development](#go-module-development)
3. [Data Export and Analysis](#data-export-and-analysis)

---

## Viam CLI Patterns

### Calling DoCommand on a Generic Service

The `--service` flag does NOT exist. Use the full gRPC method name:

```bash
viam machine part run --part <part_id> \
  --method 'viam.service.generic.v1.GenericService.DoCommand' \
  --data '{"name": "<service-name>", "command": {"command": "<cmd>", ...}}'
```

**Example:**
```bash
viam machine part run --part $PART_ID \
  --method 'viam.service.generic.v1.GenericService.DoCommand' \
  --data '{"name": "cycle-tester", "command": {"command": "execute_cycle"}}'
```

### Calling DoCommand on a Component

Use `--component` flag (shorthand available):

```bash
viam machine part run --part <part_id> --component <name> --method DoCommand --data '{...}'
```

Or full method:
```bash
viam machine part run --part <part_id> \
  --method 'viam.component.generic.v1.GenericService.DoCommand' \
  --data '{"name": "<component-name>", "command": {...}}'
```

### Getting Machine Status

```bash
viam machine part run --part <part_id> \
  --method 'viam.robot.v1.RobotService.GetMachineStatus' \
  --data '{}'
```

### Viewing Logs

```bash
viam machine logs --machine <machine_id> --count <N> [--keyword <filter>]
```

**Note:** Uses `--machine` (machine_id), not `--part` (part_id).

### Common gRPC Method Names

| Purpose | Method |
|---------|--------|
| Generic Service DoCommand | `viam.service.generic.v1.GenericService.DoCommand` |
| Generic Component DoCommand | `viam.component.generic.v1.GenericService.DoCommand` |
| Machine Status | `viam.robot.v1.RobotService.GetMachineStatus` |
| Resource Names | `viam.robot.v1.RobotService.ResourceNames` |

### Known CLI Limitations

- **No command to fetch machine config** - must use Viam app UI
- **No `--service` flag** - use full gRPC method name instead
- **Logs use machine_id, not part_id** - different from most other commands

---

## Go Module Development

### Accessing Dependencies in Constructor

```go
func NewController(ctx context.Context, deps resource.Dependencies, name resource.Name, conf *Config, logger logging.Logger) (resource.Resource, error) {
    // Access a dependency declared in Validate()
    arm, err := arm.FromDependencies(deps, conf.ArmName)
    if err != nil {
        return nil, fmt.Errorf("failed to get arm %q: %w", conf.ArmName, err)
    }

    return &controller{
        name:   name,
        logger: logger,
        cfg:    conf,
        arm:    arm,
    }, nil
}
```

### Declaring Dependencies in Validate

```go
func (cfg *Config) Validate(path string) ([]string, []string, error) {
    if cfg.ArmName == "" {
        return nil, nil, fmt.Errorf("%s: missing required field 'arm'", path)
    }
    // First return: required dependencies
    // Second return: optional dependencies
    return []string{cfg.ArmName}, nil, nil
}
```

### DoCommand Pattern with Command Routing

```go
func (c *controller) DoCommand(ctx context.Context, cmd map[string]interface{}) (map[string]interface{}, error) {
    cmdName, ok := cmd["command"].(string)
    if !ok {
        return nil, errors.New("missing 'command' field")
    }

    switch cmdName {
    case "start_cycle":
        return c.handleStartCycle(ctx, cmd)
    case "stop_cycle":
        return c.handleStopCycle(ctx)
    case "get_status":
        return c.handleGetStatus(ctx)
    default:
        return nil, fmt.Errorf("unknown command: %s", cmdName)
    }
}
```

### Testing with Mock Dependencies

```go
func TestDoCommand(t *testing.T) {
    logger := logging.NewTestLogger(t)
    name := resource.NewName(resource.APINamespaceRDK.WithServiceType("generic"), "test")

    ctrl, err := NewController(context.Background(), nil, name, &Config{}, logger)
    require.NoError(t, err)

    cmd := map[string]interface{}{
        "command": "get_status",
    }

    resp, err := ctrl.(*controller).DoCommand(context.Background(), cmd)
    require.NoError(t, err)
    assert.Equal(t, "ok", resp["status"])
}
```

### Background Goroutine with Cancellation

```go
type controller struct {
    cancelCtx  context.Context
    cancelFunc func()
    // ...
}

func NewController(...) (resource.Resource, error) {
    cancelCtx, cancelFunc := context.WithCancel(context.Background())

    c := &controller{
        cancelCtx:  cancelCtx,
        cancelFunc: cancelFunc,
    }

    // Start background work
    go c.runBackgroundLoop()

    return c, nil
}

func (c *controller) runBackgroundLoop() {
    ticker := time.NewTicker(time.Second)
    defer ticker.Stop()

    for {
        select {
        case <-c.cancelCtx.Done():
            return
        case <-ticker.C:
            // Do periodic work
        }
    }
}

func (c *controller) Close(ctx context.Context) error {
    c.cancelFunc() // Signals background goroutines to stop
    return nil
}
```

---

## Data Export and Analysis

### Exporting Tabular Sensor Data

```bash
viam data export tabular \
  --destination=/tmp/sensor-data \
  --part-id=<part_id> \
  --resource-name=<sensor_name> \
  --resource-subtype=rdk:component:sensor \
  --method=Readings
```

**Key flags:**
- `--resource-subtype` must be full API path: `rdk:component:sensor` (not just `sensor`)
- `--method` is typically `Readings` for sensors
- `--start` and `--end` accept ISO-8601 timestamps for time filtering

**Get IDs from machine.json:**
```bash
cat machine.json | jq '{part_id, machine_id, org_id}'
```

### Data Format

Output is NDJSON (newline-delimited JSON). Each line:
```json
{
  "partId": "...",
  "resourceName": "force-sensor",
  "resourceSubtype": "rdk:component:sensor",
  "methodName": "Readings",
  "timeCaptured": "2026-01-20T13:06:36.907Z",
  "payload": {
    "readings": {
      "capture_state": "capturing",
      "cycle_count": 3,
      "max_force": 200,
      "sample_count": 100,
      "samples": [71, 74, 77, ...],
      "should_sync": true,
      "trial_id": "trial-20260120-080817"
    }
  }
}
```

### Analysis Patterns

**Find unique values:**
```bash
grep -o '"trial_id":"[^"]*"' data.ndjson | sort -u
grep -o '"cycle_count":[0-9]*' data.ndjson | sort -u
```

**Count by field value:**
```bash
grep -c '"should_sync":true' data.ndjson
grep -c '"should_sync":false' data.ndjson
```

**Filter with jq (for smaller datasets or sampled data):**
```bash
# Readings with samples
cat data.ndjson | jq -c 'select(.payload.readings.sample_count > 0)'

# Readings from specific trial
grep '"trial_id":"trial-123"' data.ndjson | jq -s '{
  total: length,
  max_force: ([.[].payload.readings.max_force // 0] | max),
  max_samples: ([.[].payload.readings.sample_count] | max)
}'

# Extract sample array from full capture
grep '"sample_count":100' data.ndjson | head -1 | jq '.payload.readings.samples'
```

**For large files (800MB+):**
- Use `grep` for filtering before `jq` (much faster)
- Use `head -N` or `tail -N` to sample data
- Avoid complex jq on full file (memory issues)

### Conditional Sync Analysis

The `should_sync` field determines if data uploads to cloud:
- `true` during active trials (trial_id is set)
- `false` during idle time

To see only trial data:
```bash
grep '"should_sync":true' data.ndjson | wc -l
```

### Common Issues

1. **Empty results**: Check `--resource-subtype` uses full path `rdk:component:sensor`
2. **Permission denied in jq**: Large file + complex query; use grep to filter first
3. **Memory issues**: Don't load entire file into jq; stream or sample instead

---

## Additional Resources

- [Viam Documentation](https://docs.viam.com)
- [Viam Go SDK](https://pkg.go.dev/go.viam.com/rdk)
- [Viam CLI Reference](https://docs.viam.com/cli)
