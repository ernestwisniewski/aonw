# API protocol

App-side multiplayer codecs. Canonical wire DTOs and protocol versioning live
in `packages/aonw_core/lib/protocol`, while this directory adapts Flutter app
save/domain objects to and from those shared wire envelopes.

See [ADR 0003](../../../docs/adr/0003-command-boundaries.md) for the command
taxonomy and [ADR 0004](../../../docs/adr/0004-versioned-multiplayer-protocol.md)
for the accepted compatibility and generated-code boundaries. Both ADRs are
implemented at this boundary; this file describes the current adapter location.
