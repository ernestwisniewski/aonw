import 'package:aonw/l10n/game_text.dart';

String enumLabelList(Iterable<Enum> values, {required String empty}) {
  if (values.isEmpty) return empty;
  return values.map((value) => humanEnumName(value.name)).join(' + ');
}

String humanEnumName(String name) {
  final words = name.replaceAll('_', ' ').split(' ');
  return words
      .map((word) => word.isEmpty ? word : GameText.capitalize(word))
      .join(' ');
}
