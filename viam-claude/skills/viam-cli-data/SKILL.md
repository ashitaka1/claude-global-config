---
name: viam-cli-data
description: Provides Viam CLI data for the project. Use when you need to supply arguments to the viam CLI for the various cloud resources used in the project, like org ids, machine ids, etc.
---

# Viam CLI Data

Machine resources are stored in @viam-cli-data.json with two top-level keys:
- `machines`: Contains all machine configurations, keyed by machine name
- `roles`: Maps role names (e.g., 'dev_machine') to machine names

## Accessing Machines by Role

To access a machine by its role, first look up the machine name in `.roles`, then retrieve the machine data from `.machines`:

```bash
# Get the dev_machine configuration
jq &#x27;.machines[.roles.dev_machine]&#x27; viam-cli-data.json

# Get a specific field from the dev_machine
jq &#x27;.machines[.roles.dev_machine].machine_id&#x27; viam-cli-data.json

## Machine Fields

Each machine in `.machines` contains:

| Field | Description |
|-------|-------------|
| `org_id` or `organization_id` | Viam organization ID |
| `machine_id` | Viam machine ID |
| `part_id` | Machine part ID for the main part |
| `location_id` | Viam location ID |
| `machine_address` | Cloud hostname for the machine |
| `part_name` | (Optional) Name of the machine part |


