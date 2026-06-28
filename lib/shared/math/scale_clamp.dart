double clampFiniteScale(
  double value, {
  double min = 1.0,
  double max = 2.4,
  double fallback = 1.0,
}) {
  if (!value.isFinite) return fallback;
  return value.clamp(min, max).toDouble();
}

double clampMarkerScale(double value, {double min = 1.0, double max = 2.4}) {
  return clampFiniteScale(value, min: min, max: max);
}
