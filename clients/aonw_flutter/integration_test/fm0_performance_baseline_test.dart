import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui';

import 'package:aonw_flutter/app/composition/app_composition.dart';
import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vm_service/vm_service.dart' show VmService;
import 'package:vm_service/vm_service_io.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('records the FM0 CustomPainter viewport baseline', (
    tester,
  ) async {
    final rssBefore = ProcessInfo.currentRss;
    final startup = Stopwatch()..start();
    await tester.pumpWidget(AppComposition.production().root);
    await tester.pumpAndSettle();
    startup.stop();

    final canvas = find.byKey(const ValueKey('map-canvas'));
    expect(canvas, findsOneWidget);
    expect(aonwRustClientIdentity.isCompatible, isTrue);

    Future<void> hoverWorkload(int frames) async {
      final renderBox = tester.renderObject<RenderBox>(canvas);
      final size = renderBox.size;
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(
        location: renderBox.localToGlobal(const Offset(2, 2)),
      );
      for (var frame = 0; frame < frames; frame++) {
        final x = 8 + (frame * 17 % (size.width - 16).floor());
        final y = 8 + (frame * 29 % (size.height - 16).floor());
        await mouse.moveTo(
          renderBox.localToGlobal(Offset(x.toDouble(), y.toDouble())),
        );
        await tester.pump(const Duration(microseconds: 16667));
      }
      await mouse.removePointer();
    }

    await hoverWorkload(12);
    final allocationConnection = await _connectToVmService();
    final allocationService = allocationConnection.service;
    final isolateId = allocationConnection.isolateId;
    late final int allocationInstances;
    late final int allocationBytes;
    try {
      await allocationService.getAllocationProfile(
        isolateId,
        reset: true,
        gc: true,
      );
      await hoverWorkload(60);
      final allocationProfile = await allocationService.getAllocationProfile(
        isolateId,
      );
      final members = allocationProfile.members ?? const [];
      allocationInstances = members.fold(
        0,
        (total, member) => total + (member.instancesAccumulated ?? 0),
      );
      allocationBytes = members.fold(
        0,
        (total, member) => total + (member.accumulatedSize ?? 0),
      );
    } finally {
      await allocationService.dispose();
    }
    debugProfilePaintsEnabled = true;
    try {
      await binding.traceAction(
        () => hoverWorkload(30),
        streams: const ['Dart', 'Embedder', 'GC'],
        reportKey: 'fm0PaintTimeline',
      );
    } finally {
      debugProfilePaintsEnabled = false;
    }
    await binding.watchPerformance(
      () => hoverWorkload(60),
      reportKey: 'fm0FrameTimes',
    );

    final report = binding.reportData!;
    final timeline = report['fm0PaintTimeline']! as Map<String, dynamic>;
    final events = timeline['traceEvents']! as List<dynamic>;
    final paintEvents = events.where((event) {
      final value = event! as Map<String, dynamic>;
      return value['name'].toString().startsWith('PAINT');
    }).length;
    final record = <String, Object?>{
      'schemaVersion': 1,
      'environment': {
        'operatingSystem': Platform.operatingSystemVersion,
        'dart': Platform.version,
        'buildMode': 'flutter-test-device-debug',
        'nativeBuildIdentity': aonwRustClientIdentity.buildIdentity,
        'flame': '1.38.0',
      },
      'workload': {
        'mapId': 'aonw2_starter',
        'dimensions': {'cols': 7, 'rows': 7},
        'warmupHoverFrames': 12,
        'allocationHoverFrames': 60,
        'timedHoverFrames': 90,
        'layers': [
          'terrain',
          'reference',
          'grid',
          'interaction',
          'movement',
          'units',
        ],
      },
      'metrics': {
        'startupMicros': startup.elapsedMicroseconds,
        'residentMemoryDeltaBytes': ProcessInfo.currentRss - rssBefore,
        'allocatedInstances': allocationInstances,
        'allocatedBytes': allocationBytes,
        'profiledPaintEvents': paintEvents,
        'frameTimes': report['fm0FrameTimes'],
      },
      'policy': {
        'classification': 'diagnostic-fm0-oracle',
        'owner': 'Flutter client',
        'rebaseline':
            'Run this test on the pinned macOS host and review the diff.',
      },
    };
    // This stable marker is captured into the committed FM0 baseline record.
    // ignore: avoid_print
    print('AONW_FM0_BASELINE ${jsonEncode(record)}');
  });
}

Future<({VmService service, String isolateId})> _connectToVmService() async {
  final info = await developer.Service.getInfo();
  final server = info.serverUri;
  if (server == null) throw StateError('VM Service is unavailable.');
  final address = 'ws://localhost:${server.port}${server.path}ws';
  final service = await vmServiceConnectUri(address);
  final vm = await service.getVM();
  final isolates = vm.isolates!;
  final isolate = isolates.firstWhere(
    (candidate) => candidate.name == 'main',
    orElse: () =>
        isolates.firstWhere((candidate) => candidate.isSystemIsolate != true),
  );
  return (service: service, isolateId: isolate.id!);
}
