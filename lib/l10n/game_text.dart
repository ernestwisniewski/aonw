abstract final class GameText {
  static String uppercase(String text) => text.toUpperCase();

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return uppercase(text[0]) + text.substring(1);
  }

  static String actionLabel(String text) => uppercase(text);

  static String menuLabel(String text) => uppercase(text);

  static String screenTitle(String text) => uppercase(text);

  static String sectionLabel(String text) => uppercase(text);
}
