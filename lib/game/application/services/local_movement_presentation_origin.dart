/// Identifies the local presentation flow that produced a movement command.
///
/// This is application-only provenance. It is deliberately absent from the
/// domain command and persistence formats because replayed commands are direct
/// authoritative inputs, not confirmations of a local preview.
enum LocalMovementPresentationOrigin { direct, previewConfirmation }
