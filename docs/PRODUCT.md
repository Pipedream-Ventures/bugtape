# Product direction

## Job to be done

When an iOS developer notices something wrong while using a Simulator build,
they want to speak naturally and point at the problem, then give an agent enough
grounded context to investigate without rewriting the session as a ticket.

## Value path

1. Start or import a Simulator recording.
2. Narrate what is wrong, expected, uncertain, or merely an idea.
3. Preserve the original evidence and collect machine-readable context.
4. Review a short, timestamped issue index.
5. Give the portable bundle to a local coding agent.
6. Let the agent verify, fix, and eventually replay the flow.

## Principles

- **Evidence before synthesis.** Original media and timestamps are primary.
- **Local before hosted.** Files work without an account or service.
- **Agent-readable and human-readable.** JSON is the contract; Markdown is the
  review surface.
- **No magical claims.** A screen recording proves pixels and audio, not causes.
- **Progressive instrumentation.** Add logs, accessibility, and network context
  when available without requiring an app SDK.
- **Reviewable automation.** Generated tests remain drafts until verified.

## Initial audience

Solo iOS developers and small Swift teams using Codex, Claude Code, or Cursor
against Simulator builds. Physical-device and cross-platform QA can follow.

## Competitive boundary

clip.qa already offers mobile capture, hosted AI reports, integrations, and
CLI/MCP access. qckfx offers deterministic Simulator record/replay and visual
diffs. Screen Flow Pro offers recording, transcript, and markers. BugTape should
win by being a transparent open interchange layer and composable local tool,
not by making broader promises with a smaller implementation.

## Success criteria for v0.1

- A fresh clone builds and tests with SwiftPM.
- One command turns a real recording and optional notes/transcript into a valid,
  portable bundle.
- Every Markdown observation maps to a timestamp in JSON and, when possible, an
  extracted frame.
- No recording leaves the machine.
