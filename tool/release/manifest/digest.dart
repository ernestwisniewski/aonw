import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../canonical_json.dart';

Uint8List encodeCanonicalJsonBytes(Object? value) =>
    Uint8List.fromList(utf8.encode(encodeCanonicalJson(value)));

String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();
