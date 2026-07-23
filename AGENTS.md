# BugTape agent guide

BugTape is a local-first, open-source QA handoff tool for iOS developers. It
turns a narrated Simulator recording into a portable bundle that coding agents
can read without a hosted service.

## Product boundary

- Preserve the source recording. Do not silently mutate or upload it.
- Produce deterministic Markdown and JSON before adding model-generated prose.
- Be explicit about captured evidence versus inferred behavior.
- Never claim tap, network, accessibility, or log capture unless the bundle
  contains that evidence.
- Keep the core usable without an account, API key, SDK, or cloud service.

## Commands

```bash
swift build
swift test
swift run bugtape help
```

## Code style

- Swift 6, explicit types at public boundaries, no forced unwraps.
- Keep parsing and rendering in `BugTapeCore`; the executable owns process I/O.
- New bundle fields must remain backward-compatible or increment `schemaVersion`.
- Every parser or renderer change needs a focused test.

## Safety

Recordings can contain credentials, private messages, health data, and customer
information. Do not upload, commit, or print recording contents. Future
redaction must default to preserving the original locally while exporting a
separate sanitized artifact.
