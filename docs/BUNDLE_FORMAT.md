# BugTape bundle format v1

`manifest.json` is the durable interface. Consumers must ignore unknown fields.

## Top-level fields

| Field | Meaning |
|---|---|
| `schemaVersion` | Integer bundle contract version; currently `1` |
| `id` | Stable UUID for this compilation |
| `title` | Human-readable session title |
| `createdAt` | ISO 8601 compilation time |
| `source` | Original filename and relative path in the bundle |
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
