String percent(double value, [bool fraction = true, bool symbol = true]) {
  final rounded = (fraction ? value * 100 : value).round().toString();
  return symbol ? '$rounded%' : rounded;
}
