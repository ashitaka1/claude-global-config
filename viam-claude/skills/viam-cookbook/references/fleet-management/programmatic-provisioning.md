# Programmatic Machine Provisioning

Create machines and retrieve their deployable credentials using the Viam CLI
and fleet management SDK (Python or Go).

## When to use

When automating fleet provisioning — creating machines in bulk and staging
their `/etc/viam.json` files for deployment (PXE, SD card flashing, etc.).

## The pattern

### Step 1: Create the machine (CLI)

```sh
viam machines create \
    --name="my-machine-01" \
    --organization="<org-id>" \
    --location="<location-id>"
```

Output: `created new machine with id <machine-uuid>`

Both `--organization` and `--location` are required for unambiguous targeting.

### Step 2: Get the part ID (CLI)

Every new machine gets a default "main" part. Retrieve its ID:

```sh
viam machines part list \
    --organization="<org-id>" \
    --machine="<machine-uuid>"
```

Output format:
```
Parts:
    ID: <part-uuid>
    Name: my-machine-01-main (main)
    Last Access: ...
```

Parse the UUID from the `ID:` line. Note: this is a different format from
`viam machines list`, which shows `(main part id: <uuid>)` inline.

Alternatively, `viam machines list` output already includes the part ID:
```
my-machine-01 (id: <machine-uuid>) (main part id: <part-uuid>)
```

### Step 3: Fetch cloud credentials (SDK)

The CLI cannot retrieve cloud credentials. Use the fleet management API
via the Python or Go SDK.

**Python:**

```python
import asyncio
import json

from viam.app.viam_client import ViamClient
from viam.rpc.dial import Credentials, DialOptions


async def fetch_cloud_credentials(
    api_key_id: str,
    api_key: str,
    part_id: str,
) -> dict:
    """Fetch the cloud credentials for a machine part.

    Uses a provisioning key (org/location-scoped API key) to authenticate.
    Returns the content for /etc/viam.json.
    """
    dial_options = DialOptions(
        credentials=Credentials(type="api-key", payload=api_key),
        auth_entity=api_key_id,
    )
    client = await ViamClient.create_from_dial_options(dial_options)

    try:
        part = await client.app_client.get_robot_part(robot_part_id=part_id)
        return {
            "cloud": {
                "app_address": "https://app.viam.com:443",
                "id": part.id,
                "secret": part.secret,
            }
        }
    finally:
        result = client.close()
        if result is not None:
            await result
```

**Go:**

```go
import (
    "context"
    "encoding/json"
    "os"

    "go.viam.com/rdk/app"
    "go.viam.com/utils/rpc"
)

func fetchCloudCredentials(ctx context.Context, apiKeyID, apiKey, partID string) error {
    client, err := app.NewAppClient(ctx,
        rpc.WithEntityCredentials(apiKeyID,
            rpc.Credentials{Type: rpc.CredentialsTypeAPIKey, Payload: apiKey},
        ),
    )
    if err != nil {
        return err
    }
    defer client.Close()

    part, _, err := client.GetRobotPart(ctx, partID)
    if err != nil {
        return err
    }

    viamJSON := map[string]any{
        "cloud": map[string]any{
            "app_address": "https://app.viam.com:443",
            "id":          part.Id,
            "secret":      part.Secret,
        },
    }

    f, err := os.Create("viam.json")
    if err != nil {
        return err
    }
    defer f.Close()
    return json.NewEncoder(f).Encode(viamJSON)
}
```

The provisioning key used here is any API key authorized for the org or
location — it does not need to be the machine's own key.

### Step 4: Deploy viam.json

Deploy the generated file to `/etc/viam.json` on the target machine via your
provisioning mechanism (PXE server, SD card, SSH, etc.).

## Complete scripting example

Listing existing machines to find the next available number:

```sh
viam machines list \
    --organization="<org-id>" \
    --location="<location-id>"
```

Output (one machine per line):
```
my-machine-01 (id: <uuid>) (main part id: <uuid>)
my-machine-02 (id: <uuid>) (main part id: <uuid>)
```

Parse this to find the highest existing number for your prefix, then create
the next batch starting from highest + 1.

## Key points

- The CLI requires `--organization` on most commands, even when
  `--location` alone seems sufficient. Omitting it produces errors or
  ambiguous results.
- `viam machines create` only returns the machine ID. You must separately
  retrieve the part ID (from `part list` or `machines list` output).
- Cloud credentials come from `GetRobotPart` / `get_robot_part` in the
  fleet management SDK, not from any CLI command.
- **Python auth:** Use `DialOptions` with `Credentials`. The pattern
  `ViamClient.Options.with_api_key()` does not exist despite appearing
  in some documentation — it will raise `AttributeError`.
- **Go auth:** Use `app.NewAppClient` with `rpc.WithEntityCredentials`.
- **Python SDK quirk:** `client.close()` may return `None` in some SDK
  versions. Guard with `if result is not None: await result`.
- Install the Python SDK via pip: `pip install viam-sdk`. Use a venv on
  systems with externally-managed Python (macOS Homebrew, recent Debian).

## Pitfalls

- **Don't confuse API key output with cloud credentials.** `viam machines
  api-key create` produces API keys for SDK access, not the cloud
  credentials needed for viam.json. See the credential-model recipe.
- **Don't try to retrieve the machine's default API key via CLI.** There
  is no CLI command to do this. Use the provisioning key pattern instead.
- **Parse CLI output carefully.** `machines list` and `machines part list`
  use different output formats. The UUID regex `[a-f0-9-]{36}` matches
  both, but be aware of which UUID you're capturing (machine ID vs part ID).
