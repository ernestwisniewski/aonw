import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWasm;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'webp_asset_probe.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _WebpDecodeSmokeApp());
}

class _WebpDecodeSmokeApp extends StatelessWidget {
  const _WebpDecodeSmokeApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _WebpDecodeSmokeScreen(),
    );
  }
}

class _WebpDecodeSmokeScreen extends StatefulWidget {
  const _WebpDecodeSmokeScreen();

  @override
  State<_WebpDecodeSmokeScreen> createState() => _WebpDecodeSmokeScreenState();
}

class _WebpDecodeSmokeScreenState extends State<_WebpDecodeSmokeScreen> {
  static const mode = String.fromEnvironment(
    'WEBP_SMOKE_MODE',
    defaultValue: 'unknown',
  );

  String _status = 'WEBP_SMOKE_RUNNING mode=$mode';

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    try {
      const compiler = kIsWasm ? 'wasm' : 'js';
      if (mode != compiler) {
        throw StateError(
          'Requested $mode smoke, but the active Dart compiler is $compiler',
        );
      }
      final result = await probeBundledWebpAssets();
      if (!mounted) return;
      setState(() {
        _status =
            'WEBP_SMOKE_OK mode=$mode '
            'compiler=$compiler '
            'atlases=${result.atlasCount} '
            'pages=${result.pageCount} '
            'frames=${result.frameCount}';
      });
      debugPrint(_status);
      _reportToCallback(_status);
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _status = 'WEBP_SMOKE_FAILED mode=$mode\n$error\n$stackTrace';
      });
      debugPrint(_status);
      _reportToCallback(_status);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D12),
      body: Center(
        child: SelectableText(
          _status,
          key: const ValueKey('webp-smoke-status'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}

void _reportToCallback(String status) {
  const callback = String.fromEnvironment('WEBP_SMOKE_CALLBACK_URL');
  if (callback.isEmpty) return;
  final uri = Uri.parse(callback).replace(queryParameters: {'status': status});
  web.window.navigator.sendBeacon(uri.toString());
}
