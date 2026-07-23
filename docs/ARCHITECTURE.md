# Architecture

TAPE is a Swift Package with a native macOS app, a small executable, and a
reusable core. The GUI and CLI compile the same local evidence format.

```text
Apple capture / simctl / imported video
          |
          v
   TAPE Mac app or CLI
          |
          +--> AVFoundation metadata + frames
          +--> SRT / VTT / notes parsers
          +--> simctl environment probe
          |
          v
   Bundle compiler
          |
          +--> manifest.json (stable contract)
          +--> report.md (agent/human entry point)
          +--> source video
          +--> evidence frames
```

## Targets

- `BugTapeCore`: domain models, parsers, metadata extraction, frame extraction,
  bundle compilation, and Markdown rendering.
- `AppTapeApp`: native SwiftUI capture, permission status, TL;DR, review,
  archive, and agent-handoff workflow.
- `bugtape`: command parsing, `simctl` process control, and terminal output.
- `BugTapeCoreTests`: deterministic tests for timestamp parsing, notes,
  subtitles, and report rendering.

## Trust model

`source` and `captured` fields are evidence. `expected` notes are human claims.
Future AI summaries must be stored as `inferences` with model/provider metadata
and cannot overwrite captured evidence.

## Privacy model

The compiler performs local file operations only. The source recording is
copied rather than changed. Future redaction should produce a derived export
with a provenance link to the local original.

## Platform choices

AVFoundation provides native media metadata and frame extraction without
shipping ffmpeg. Apple's screen recorder handles display/window selection and
microphone capture; TAPE owns the launch, live state, stop action, and
post-capture handoff. `xcrun simctl` remains the lower-level Simulator path.
