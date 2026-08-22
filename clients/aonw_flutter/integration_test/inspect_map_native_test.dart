import 'package:aonw_flutter/app/composition/app_composition.dart';
import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Rust inspects the packaged starter through the native adapter', (
    tester,
  ) async {
    expect(aonwRustClientAvailable, isTrue);
    final session = await createAonwRustSession();
    expect(session, isNotNull);
    addTearDown(session!.close);

    final document = await rootBundle.loadString(
      'assets/maps/aonw2_starter/map.json',
    );
    final response = await session.send(
      AonwClientRequest.inspectMap(mapDocument: document),
    );
    final map = response.require<AonwMapInspectedResponse>().map;
    expect(map.mapId, 'aonw2_starter');
    expect(map.tiles, hasLength(49));
    expect(map.gridLayout, AonwMapGridLayout.oddQFlatTop);
  });

  testWidgets('standalone app renders the Rust-backed starter bundle', (
    tester,
  ) async {
    await tester.pumpWidget(const AppComposition().build());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('map-canvas')), findsOneWidget);
    expect(find.text('Map unavailable'), findsNothing);
  });
}
