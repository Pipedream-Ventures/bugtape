# Contributing to BugTape

BugTape is intentionally early. Small, evidenced improvements are more useful
than broad claims or speculative abstractions.

## Before opening a pull request

```bash
swift build
swift test
```

Include a focused test for parser, schema, or renderer behavior. If a change
adds a captured signal, document where that signal comes from and how a user can
distinguish it from inference.

## Good first contributions

- More subtitle fixture coverage
- JSON Schema generation and validation
- Safe recording filename handling
- Better `simctl` environment metadata
- A redaction threat model
- Export adapters that consume the bundle without changing its evidence

Please do not add a required hosted service, analytics, or an app
instrumentation SDK to the local core.

## Reporting security or privacy problems

Do not open a public issue containing a sensitive recording, credential, or
customer data. Until a public security contact is established, share only a
minimal reproduction with the repository owner through a private channel.
