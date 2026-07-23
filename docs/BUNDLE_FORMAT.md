# TAPE bundle format v3

`manifest.json` is the durable interface. Consumers must ignore unknown fields.

## Top-level fields

| Field | Meaning |
|---|---|
| `schemaVersion` | Integer bundle contract version; currently `3` |
| `id` | Stable UUID for this compilation |
| `title` | Human-readable session title |
| `summary` | Optional tester-written TL;DR of what they recorded |
| `createdAt` | ISO 8601 compilation time |
| `source` | Original filename, optional relative path, and whether source is bundled |
| `video` | Duration, dimensions, audio presence, and byte size |
| `environment` | Host and best-effort booted Simulator context |
| `observations` | Timestamped human notes and transcript cues |
| `frames` | Extracted visual evidence and source timestamps |

## Observation trust

Each observation includes `kind`:

- `note`: explicitly provided by the tester
- `transcript`: parsed from a subtitle sidecar
- `transcriptDocument`: untimed plain text

`label` is user-defined and is not treated as severity without an explicit
future mapping.

## Compatibility

Adding optional fields does not change the schema version. Renaming fields,
changing meanings, or removing values requires a new version and migration
notes.

Version 2 makes `source.relativePath` optional and adds `source.isBundled`.
This supports compact research bundles that preserve timeline evidence without
duplicating a large source recording.

Version 3 adds the optional top-level `summary` field. The native Mac app
requires it for new tapes and renders it as **In their words** before machine
metadata and timeline evidence. Existing v2 bundles remain readable.
