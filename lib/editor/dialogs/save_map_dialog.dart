import 'package:aonw/editor/dialogs/editor_image_slice_toggle.dart';
import 'package:aonw/editor/services/map_saver.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:flutter/material.dart';

typedef SaveMapDialogResult = ({
  String name,
  String? imageSourcePath,
  bool sliceImage,
});

Future<SaveMapDialogResult?> showSaveMapDialog(
  BuildContext context, {
  required String initialName,
}) {
  return showGameModal<SaveMapDialogResult>(
    context: context,
    requestFocus: true,
    builder: (_) => _SaveMapDialog(initialName: initialName),
  );
}

class _SaveMapDialog extends StatefulWidget {
  const _SaveMapDialog({required this.initialName});

  final String initialName;

  @override
  State<_SaveMapDialog> createState() => _SaveMapDialogState();
}

class _SaveMapDialogState extends State<_SaveMapDialog> {
  late final TextEditingController _controller;
  final _nameFocusNode = FocusNode();

  late String _name;
  String? _imageSourcePath;
  bool _sliceImage = false;

  @override
  void initState() {
    super.initState();
    _name = widget.initialName;
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameModalScaffold(
      header: const GameModalHeader(title: 'Save Map'),
      content: _content(),
      actions: [
        GameModalAction(
          label: 'CANCEL',
          variant: EpicButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(),
        ),
        GameModalAction(
          label: 'SAVE',
          variant: EpicButtonVariant.primary,
          onPressed: _submit,
        ),
      ],
    );
  }

  Widget _content() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _nameField(),
        const SizedBox(height: 12),
        _imagePicker(),
        if (_imageSourcePath != null) ...[
          const SizedBox(height: 4),
          EditorImageSliceToggle(
            value: _sliceImage,
            onChanged: (value) => setState(() => _sliceImage = value),
          ),
        ],
      ],
    );
  }

  Widget _nameField() {
    return TextField(
      controller: _controller,
      focusNode: _nameFocusNode,
      autofocus: true,
      textInputAction: TextInputAction.done,
      style: GameUiTheme.inputText,
      decoration: const InputDecoration(
        labelText: 'Map name',
        labelStyle: TextStyle(color: GameUiTheme.textSecondary),
      ),
      onChanged: (value) => _name = value.isEmpty ? 'map' : value,
      onSubmitted: (value) => _submit(name: value.isEmpty ? 'map' : value),
    );
  }

  Widget _imagePicker() {
    return TextButton(
      onPressed: _pickImage,
      style: TextButton.styleFrom(
        foregroundColor: GameUiTheme.textPrimary,
        padding: EdgeInsets.zero,
        textStyle: GameUiTheme.actionLabel,
      ),
      child: Text(
        _imageSourcePath == null
            ? 'CHOOSE IMAGE (optional)'
            : 'Image: ${editorImageFileName(_imageSourcePath!)}',
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedPath = await MapSaver.pickImage();
    if (pickedPath == null || !mounted) return;
    setState(() => _imageSourcePath = pickedPath);
  }

  void _submit({String? name}) {
    Navigator.of(context).pop((
      name: name ?? _name,
      imageSourcePath: _imageSourcePath,
      sliceImage: _sliceImage,
    ));
  }
}
