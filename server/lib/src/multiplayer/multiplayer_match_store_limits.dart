part of 'multiplayer_match_store.dart';

/// Maximum number of authoritative events returned after a caller-provided
/// offset. Callers continue with the last returned offset to read the next
/// stable page.
const multiplayerEventPageSize = 256;

/// Maximum number of running matches inspected by one timeout sweep.
const multiplayerRunningMatchPageSize = 64;

/// Participant-owned active matches are queried independently so a busy public
/// lobby list cannot hide private or resumable matches from the caller.
const multiplayerVisibleParticipantMatchLimit = 64;

/// Maximum number of public open lobbies returned by the discovery query.
const multiplayerVisiblePublicLobbyLimit = 128;

/// Maximum number of open quickplay rows inspected by one store query.
const multiplayerQuickplayCandidateScanLimit = 16;

/// Maximum number of stale or legacy quickplay candidates retired by a single
/// matchmaking request before a fresh lobby is created.
const multiplayerQuickplayCandidateRetirementLimit = 8;
