# Architecture

BugTape starts as a Swift Package with a small executable and a reusable core.
That keeps the first artifact scriptable, testable, and ready to embed in a
future native macOS app.

```text
simctl / imported video
          |
          v
     BugTape CLI
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
shipping ffmpeg. `xcrun simctl` is the public Xcode entry point for Simulator
recording and device context. Swift models make a future SwiftUI review app
straightforward.
