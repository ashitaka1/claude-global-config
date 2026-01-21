---
name: viam-guide
description: Viam platform best practices, CLI patterns, and Go development guide. Auto-loaded for Viam projects.
user-invocable: false
---

# Viam Platform Best Practices

This skill provides comprehensive Viam platform guidance. The full guide is available at `../docs/VIAM_GUIDE.md` within the plugin directory.

## Quick Reference

When working with Viam projects, refer to the guide for:

- **CLI command patterns** - Correct gRPC method names, part vs machine IDs
- **Go module development** - Dependencies, DoCommand routing, testing, background goroutines
- **Data export and analysis** - Sensor data export, NDJSON analysis, large file handling

## Using the Guide

The guide is in the plugin's `docs/` directory. When you need detailed information about Viam patterns:

1. **CLI patterns**: See "Viam CLI Patterns" section for gRPC methods and command syntax
2. **Go development**: See "Go Module Development" for RDK patterns
3. **Data analysis**: See "Data Export and Analysis" for working with captured data

The guide covers common issues, limitations, and best practices discovered during Viam development.
