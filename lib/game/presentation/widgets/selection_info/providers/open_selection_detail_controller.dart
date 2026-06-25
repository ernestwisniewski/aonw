import 'package:flutter_riverpod/flutter_riverpod.dart';

final openSelectionDetailControllerProvider =
    NotifierProvider<OpenSelectionDetailController, String?>(
      OpenSelectionDetailController.new,
    );

class OpenSelectionDetailController extends Notifier<String?> {
  @override
  String? build() => null;

  void open(String chipId) {
    state = chipId;
  }

  void toggle(String chipId) {
    state = state == chipId ? null : chipId;
  }

  void close() {
    state = null;
  }
}
