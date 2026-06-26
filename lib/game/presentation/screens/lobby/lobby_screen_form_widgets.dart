part of 'lobby_screen.dart';

class _LobbyLabel extends StatelessWidget {
  final String text;

  const _LobbyLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: GameUiTheme.sectionHeader);
  }
}

class _LobbyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;

  const _LobbyTextField({
    required this.controller,
    this.hintText,
    this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: GameUiTheme.inputText,
      decoration: GameUiTheme.textFieldDecoration(hintText: hintText),
      onChanged: onChanged,
    );
  }
}
