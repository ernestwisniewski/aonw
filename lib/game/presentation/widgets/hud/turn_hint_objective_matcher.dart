import 'package:aonw/l10n/generated/app_localizations.dart';

bool hudTurnHintIsObjective(AppLocalizations l10n, String? label) {
  final normalized = label?.trim();
  if (normalized == null || normalized.isEmpty) return false;

  const marker = '__objective__';
  final template = l10n.turnHintObjective(marker);
  final markerIndex = template.indexOf(marker);
  if (markerIndex <= 0) return false;

  return normalized.startsWith(template.substring(0, markerIndex));
}
