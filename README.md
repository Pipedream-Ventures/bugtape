# BugTape

**Narrate an iOS bug. Hand your agent the tape.**

BugTape is an early, local-first open-source tool for turning an iOS Simulator
screen recording into an evidence bundle that Codex, Claude Code, Cursor, or a
human teammate can inspect. The bundle contains the original recording,
timestamped notes or transcript cues, representative frames, Simulator
metadata, a stable JSON manifest, and a readable Markdown report.

It does not upload your recording, require an SDK, invent reproduction steps,
or pretend a video is a deterministic test.

## Why this exists

The adjacent products are good at different jobs:

- [clip.qa](https://clip.qa/) turns mobile recordings into hosted, AI-generated
  reports and ships CLI/MCP access. Its autonomous real-device loop is
  described as coming soon.
- [qckfx](https://qckfx.com/) records and deterministically replays Simulator
  interactions, app state, network traffic, screenshots, and logs.
- [Screen Flow Pro](https://screenflowpro.app/) provides polished Mac/iOS
  recording, timecoded transcripts, voice markers, and support bundles.

BugTape's intended wedge is narrower and open: a local, inspectable file format
and CLI that compiles narrated Simulator QA into agent context. It should
eventually interoperate with—not vaguely clone—recorders and replay tools.

## Current MVP

- Record the booted Simulator using Apple's `simctl`
- Import `.mp4`, `.mov`, or `.m4v` recordings
- Read real duration, dimensions, audio presence, and file size
- Accept `.srt`, `.vtt`, or plain-text narration
- Accept explicit timestamped QA notes
- Extract JPEG evidence frames at note/transcript timestamps
- Capture the currently booted Simulator's device/runtime metadata when present
- Emit `report.md` plus a versioned `manifest.json`
- Keep the source video inside a portable directory

Local speech-to-text is deliberately not faked in v0.1. Use macOS/iOS
transcription, Screen Flow Pro, Whisper, or another local tool to create an SRT
or VTT sidecar, then pass it to BugTape. A pluggable on-device transcription
adapter is on the roadmap.

## Run it

Requires macOS 14+ and Xcode command-line tools.

```bash
swift build
swift test

# Recommended: record any Mac display or selection with microphone narration
# and visible click indicators. This works with Simulator, QuickTime's iPhone
# preview, or iPhone Mirroring.
swift run bugtape capture qa-run.mov

# Record the booted Simulator. Press Control-C to stop.
# This lower-level mode records only the device pixels and has no microphone.
swift run bugtape record qa-run.mp4

# Compile a recording into an agent-readable bundle.
swift run bugtape bundle qa-run.mp4 \
  --output BugTapeBundles/login-regression \
  --title "Login regression" \
  --transcript qa-run.srt \
  --notes qa-notes.txt

# Inspect metadata without creating a bundle.
swift run bugtape inspect qa-run.mp4
```

Timestamped notes use one line per observation:

```text
00:08 blocker Sign in does nothing after valid credentials
00:14 expected Dashboard should appear after authentication
00:21 polish Error copy shifts the button vertically
```

Supported labels are free-form. `blocker`, `bug`, `ux`, `polish`, `expected`,
and `idea` make useful conventions.

### Recommended narrated QA workflow

1. Run `swift run bugtape capture qa-run.mov`.
2. In Apple's recording toolbar, choose the whole display or draw a selection
   around Simulator/iPhone Mirroring. Under **Options**, confirm the microphone
   you want to use.
3. Record the QA session. Narrate what you expected and what happened; labels
   such as "blocker", "UX", "polish", "expected", and "idea" are useful.
4. Stop from the macOS menu bar.
5. Compile the recording with a transcript or notes sidecar:

   ```bash
   swift run bugtape bundle qa-run.mov \
     --output BugTapeBundles/paco-qa \
     --title "Paco QA" \
     --transcript qa-run.srt \
     --frame-interval 10
   ```

The `capture` command uses Apple's local screen recorder. The original `.mov`
contains the selected microphone audio and visible click indicators. BugTape
does not upload it. Automatic local speech-to-text remains a separate roadmap
item; until then, pass an SRT/VTT file or give the recording directly to an
agent that can transcribe it.

## Bundle format

```text
login-regression/
├── manifest.json
├── report.md
├── source/
│   └── qa-run.mp4
└── frames/
    ├── frame-0008.000.jpg
    └── frame-0014.000.jpg
```

Give an agent the bundle directory, or start with:

> Read `report.md` and `manifest.json`, inspect the linked evidence frames and
> source video, verify each reported observation in the app, then fix only
> confirmed issues. Keep expected behavior distinct from inference.

The JSON schema is documented in
[`docs/BUNDLE_FORMAT.md`](docs/BUNDLE_FORMAT.md).

## What BugTape does not yet do

- Detect raw pointer/tap events. A cursor visible in the recording remains
  visible in the original video and extracted frames.
- Capture app logs, network calls, or the accessibility hierarchy.
- Convert narration into authoritative expected behavior.
- Replay a flow or generate trustworthy XCUITests.
- Redact secrets or private content.
- Expose an MCP server.

Those are roadmap items, not implied features.

## Contributing

See [`docs/PRODUCT.md`](docs/PRODUCT.md),
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), and
[`docs/ROADMAP.md`](docs/ROADMAP.md). The project is MIT licensed.

The name **BugTape** is provisional. A web search found unrelated historical
uses, including an insect-control trademark, so naming and trademark clearance
must happen before a public brand launch.
