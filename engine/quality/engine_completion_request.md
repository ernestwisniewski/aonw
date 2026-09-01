# Rust Engine Completion request

- Branch: `dev`
- Purpose: final Engine-to-Client Handoff evidence
- Required commit scope: complete E0-PS11 engine, current client/native contract,
  quality and supply-chain policies
- Required workflows on one commit: CI, Dependency Vulnerability Scan,
  Successor Engine Deep Checks, Successor Engine Security Checks

Changing this file is the bootstrap dispatch mechanism while the dedicated
workflows are not yet present on the default branch. Routine engine commits do
not touch it and therefore do not start expensive mutation, fuzz, Miri,
sanitizer, or release-metadata jobs. After these workflows reach `main`, use
their normal manual dispatch instead.
