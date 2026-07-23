# TAPE

**Record an app. Hand your agent the tape.**

TAPE is a local-first Mac app for turning QA, competitor,
inspiration, or product walkthrough recordings into evidence bundles that
Codex, Claude Code, Cursor, or a human teammate can inspect. A bundle contains
the original recording or a reference to it,
timestamped notes or transcript cues, representative frames, Simulator
metadata, a stable JSON manifest, and a readable Markdown report.

It does not upload your recording, require an SDK, invent reproduction steps,
or pretend a video is a deterministic test.

## How it works

1. **Record** a screen or window with optional microphone narration.
2. **Explain** what happened in a short TL;DR; timestamp notes are optional.
3. **Hand off** a local bundle with the source, frames, metadata, and report.

## Why this exists

The adjacent products are good at different jobs:

- [clip.qa](https://clip.qa/) turns mobile recordings into hosted, AI-generated
  reports and ships CLI/MCP access. Its autonomous real-device loop is
  described as coming soon.
- [qckfx](https://qckfx.com/) records and deterministically replays Simulator
  interactions, app state, network traffic, screenshots, and logs.
- [Screen Flow Pro](https://screenflowpro.app/) provides polished Mac/iOS
  recording, timecoded transcripts, voice markers, and support bundles.

TAPE's intended wedge is narrower and open: a local, inspectable file format
and CLI that compiles narrated Simulator QA into agent context. It should
eventually interoperate with—not vaguely clone—recorders and replay tools.

## Current MVP

- Native TAPE Mac app with a visual capture, review, and archive workflow
- One primary `TAPE` action with screen/microphone permission status
- A live recording HUD with elapsed time and an in-app stop action
- Required post-recording TL;DR in the tester's own words
- Record the booted Simulator using Apple's `simctl`
- Import `.mp4`, `.mov`, or `.m4v` recordings
- Read real duration, dimensions, audio presence, and file size
- Accept `.srt`, `.vtt`, or plain-text narration
- Accept explicit timestamped QA notes
- Extract JPEG evidence frames at note/transcript timestamps
- Capture the currently booted Simulator's device/runtime metadata when present
- Emit `report.md` plus a versioned `manifest.json`
- Bundle the source video for portability, or omit its copy for compact research

Local speech-to-text is deliberately not faked in v0.1. Use macOS/iOS
transcription, Screen Flow Pro, Whisper, or another local tool to create an SRT
or VTT sidecar, then pass it to BugTape. A pluggable on-device transcription
adapter is on the roadmap.

## Run it

Requires macOS 14+ and Xcode command-line tools.

### Open the Mac app

```bash
./script/build_and_run.sh
```

The script builds and stages a real `dist/TAPE.app`, opens it, and verifies
that the GUI process launched. The same command is configured as the Codex Run
action.

For Paco on a real iPhone:

1. Connect the phone by USB, then open **QuickTime Player → New Movie
   Recording** and choose the iPhone as the camera, or use iPhone Mirroring.
2. Open TAPE.
3. Press **TAPE**, choose the QuickTime/iPhone Mirroring window in Apple's
   capture controls, and narrate while you test.
4. Stop from TAPE or the macOS menu bar.
5. Write the short **What happened?** TL;DR, add any timestamped notes, and
   build the tape.

TAPE shows whether screen and microphone access are ready, will prompt, are
blocked, or are off. After capture, it inspects the actual file and reports
whether an audio track is present.

### Use the CLI

```bash
swift build
swift test

# Recommended: record any Mac display or selection with microphone narration
# and visible click indicators. This works with Simulator, QuickTime's iPhone
# preview, or iPhone Mirroring.
swift run apptape capture qa-run.mov

# Record the booted Simulator. Press Control-C to stop.
# This lower-level mode records only the device pixels and has no microphone.
swift run apptape record qa-run.mp4

# Compile a recording into an agent-readable bundle.
swift run apptape bundle qa-run.mp4 \
  --output TapeBundles/login-regression \
  --title "Login regression" \
  --transcript qa-run.srt \
  --notes qa-notes.txt

# Inspect metadata without creating a bundle.
swift run apptape inspect qa-run.mp4
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

1. Run `swift run apptape capture qa-run.mov`.
2. In Apple's recording toolbar, choose the whole display or draw a selection
   around Simulator/iPhone Mirroring. Under **Options**, confirm the microphone
   you want to use.
3. Record the QA session. Narrate what you expected and what happened; labels
   such as "blocker", "UX", "polish", "expected", and "idea" are useful.
4. Stop from the macOS menu bar.
5. Compile the recording with a transcript or notes sidecar:

   ```bash
   swift run apptape bundle qa-run.mov \
     --output TapeBundles/paco-qa \
     --title "Paco QA" \
     --transcript qa-run.srt \
     --frame-interval 10
   ```

The `capture` command uses Apple's local screen recorder. The original `.mov`
contains the selected microphone audio and visible click indicators. TAPE
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

For a large competitor or inspiration recording, keep the original outside the
repo and create a compact evidence bundle:

```bash
swift run apptape bundle walkthrough.mp4 \
  --output TapeBundles/competitor-walkthrough \
  --notes walkthrough-notes.txt \
  --omit-source
```

The compatibility commands `swift run apptape ...` and `swift run bugtape ...`
remain available while existing scripts migrate to TAPE.

## What TAPE does not yet do

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

**TAPE** is the working product direction. Trademark and domain clearance
still need to happen before a public brand launch.
