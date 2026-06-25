import 'dart:async';

import 'package:flame/components.dart';

mixin LayerAttachment on Component {
  Component? _attachedOwner;

  Component get attachedOwner => _attachedOwner ?? this;

  void ensureAttachedTo(Component owner) {
    if (owner == this || _attachedOwner == owner) return;
    if (parent == owner) {
      _attachedOwner = owner;
      return;
    }
    if (_attachedOwner != null) {
      removeFromParent();
    }
    _attachedOwner = owner;
    unawaited(Future<void>.value(owner.add(this)));
  }

  @override
  void onRemove() {
    _attachedOwner = null;
    super.onRemove();
  }
}
