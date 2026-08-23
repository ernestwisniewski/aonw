import 'package:aonw_flutter/l10n/l10n.dart';
import 'package:flutter/material.dart';

final class LocalizedTestApp extends StatelessWidget {
  const LocalizedTestApp({
    required this.home,
    this.locale = const Locale('en'),
    this.theme,
    super.key,
  });

  final Widget home;
  final Locale locale;
  final ThemeData? theme;

  @override
  Widget build(BuildContext context) => MaterialApp(
    locale: locale,
    localizationsDelegates: AonwLocalizations.localizationsDelegates,
    supportedLocales: AonwLocalizations.supportedLocales,
    theme: theme,
    home: home,
  );
}
