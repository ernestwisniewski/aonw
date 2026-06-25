import 'package:aonw/editor/widgets/editor_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows replace map image action', (tester) async {
    var replaceTapped = false;
    var saveTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditorTopBar(
            mapData: null,
            onAddColumn: () {},
            onRemoveColumn: () {},
            onAddRow: () {},
            onRemoveRow: () {},
            onReplaceImage: () => replaceTapped = true,
            onSave: () => saveTapped = true,
            onExport: () {},
            onClose: () {},
          ),
        ),
      ),
    );

    final replaceButton = find.byTooltip('Replace map image');
    expect(replaceButton, findsOneWidget);

    await tester.tap(replaceButton);
    expect(replaceTapped, isTrue);

    await tester.tap(find.text('SAVE'));
    expect(saveTapped, isTrue);
  });
}
