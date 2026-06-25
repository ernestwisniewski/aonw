import 'package:flutter/material.dart';

enum SurfaceShape {
  frame(2),
  chip(14),
  card(10),
  button(12),
  pill(999);

  const SurfaceShape(this.radius);

  final double radius;

  BorderRadius get borderRadius => BorderRadius.circular(radius);
}
