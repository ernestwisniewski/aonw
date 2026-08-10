import 'package:flutter/material.dart';

class ManualLoopItem {
  const ManualLoopItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class ManualControlGroup {
  const ManualControlGroup({
    required this.icon,
    required this.title,
    required this.color,
    required this.items,
  });

  final IconData icon;
  final String title;
  final Color color;
  final List<ManualControlItem> items;
}

class ManualControlItem {
  const ManualControlItem({
    required this.icon,
    required this.action,
    required this.body,
  });

  final IconData icon;
  final String action;
  final String body;
}
