# API Keys vs Cloud Credentials

Viam machines have two distinct credential types that are easy to confuse.
Getting them mixed up is the most common provisioning mistake.

## When to use

When provisioning machines programmatically, writing deployment scripts, or
debugging why a machine won't connect to Viam cloud. Understanding which
credential does what prevents hours of confusion.

## The two credential types

### API Keys (authentication tokens)

Used to authenticate API requests — creating machines, fetching configs,
managing the fleet. An API key has two parts:

- **Key ID** — a UUID identifying the key
- **Key Value** — the secret token

API keys can be scoped to an org, location, or individual machine. Any
sufficiently-authorized API key can act on resources within its scope.

### Cloud Credentials (machine identity)

Used by a running machine to maintain its persistent connection to Viam cloud.
Stored in `/etc/viam.json` on the machine:

```json
{
  "cloud": {
    "app_address": "https://app.viam.com:443",
    "id": "<part-id>",
    "secret": "<part-secret>"
  }
}
```

The `id` field is the **machine part ID** (not an API key ID). The `secret`
is the **part secret** (not an API key value). These are generated when the
machine is created and are unique to that machine.

## How they relate

An API key is used once to *fetch* the cloud credentials. After that, the
machine uses its cloud credentials for all ongoing communication:

```
Provisioning key (API key)
    │
    ▼
Fleet API: GetRobotPart(part_id)  ──→  Returns: part.Id, part.Secret
    │                                   (Python SDK or Go SDK)
    ▼
Write /etc/viam.json with cloud credentials
    │
    ▼
Machine boots, viam-agent reads /etc/viam.json, connects to cloud
```

The official install script uses the same pattern via curl:

```sh
curl -fsSL \
    -H "key_id:$VIAM_API_KEY_ID" \
    -H "key:$VIAM_API_KEY" \
    "https://app.viam.com/api/json1/config?client=true&id=$VIAM_PART_ID" \
    -o /etc/viam.json
```

## Key points

- API keys are for API access. Cloud credentials are for machine identity.
- You don't need a machine's own API key to retrieve its cloud credentials —
  any authorized API key (org-level, location-level) will work.
- A "provisioning key" is just an org/location-scoped API key used by
  deployment tooling. It never gets deployed to target machines.
- The `id` in viam.json is the part ID, not an API key ID.
- Cloud credentials are created automatically when a machine is created.
  You retrieve them; you don't create them separately.

## Pitfalls

- **Don't put API keys in viam.json.** The machine expects cloud credentials
  (part ID + part secret), not API key ID + API key value. It will fail to
  connect with no useful error.
- **Don't confuse `viam machines api-key create` output with cloud credentials.**
  That command creates a new API key for SDK access. It does not produce the
  content for viam.json.
- **The CLI cannot retrieve cloud credentials directly.** You must use the
  fleet management API via the Python or Go SDK (`GetRobotPart` /
  `get_robot_part`), or the curl pattern above.
