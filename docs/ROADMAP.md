# Roadmap

## v0.1 — honest evidence bundle

- [x] `simctl` recording wrapper
- [x] Video import and native metadata
- [x] SRT, VTT, plain transcript, and timestamped notes
- [x] Evidence frames
- [x] Markdown and JSON export
- [x] Tests and documented schema

## v0.2 — better local capture

- Native SwiftUI menu-bar/session app using ScreenCaptureKit
- Timeline review, voice markers, and explicit issue ranges
- On-device Speech framework adapter packaged with the required privacy string
- Optional local Whisper adapter
- Pixel-coordinate pointer overlay captured separately from the video
- Secret/PII review and redacted derivative export

## v0.3 — Simulator evidence

- Unified `simctl` log stream scoped to the target process
- Accessibility hierarchy snapshots at markers
- App/build identity, git SHA, scheme, configuration, locale, appearance, and
  Simulator state
- Optional network metadata through a user-configured local proxy
- `.xcresult` and crash report ingestion

## v0.4 — agent loop

- Read-only MCP resources for sessions, observations, frames, and logs
- MCP tools to start/stop capture and request explicit human review
- Draft XCUITest generation from timestamped observations
- Replay verification through XcodeBuildMCP
- Adapters for qckfx flows rather than reimplementing deterministic replay

## Non-goals until evidence supports them

- Claiming fully autonomous QA
- Uploading recordings by default
- Treating generated reproduction steps as ground truth
- Shipping an instrumentation SDK inside production apps
