part of 'server_command_reducer.dart';

PersistedInteractionState? _interactionReplacement(
  PersistedInteractionState current,
  PersistedInteractionState next,
) => current == next ? null : next;
