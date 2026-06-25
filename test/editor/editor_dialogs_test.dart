import 'package:aonw/editor/dialogs/editor_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('map image upload options can toggle sliced mode', (
    tester,
  ) async {
    MapImageUploadOptions? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showMapImageUploadOptionsDialog(
                context,
                imageSourcePath: '/tmp/picked.png',
                initialSliceImage: false,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('picked.png'), findsOneWidget);
    expect(find.text('Slice image'), findsOneWidget);

    await tester.tap(find.text('Slice image'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('APPLY'));
    await tester.pumpAndSettle();

    expect(result?.sliceImage, isTrue);
  });
}
