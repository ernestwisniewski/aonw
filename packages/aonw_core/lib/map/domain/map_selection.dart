enum MapSource { asset, saved }

class MapSelection {
  static const String defaultMapName = 'map';

  final String name;
  final MapSource source;

  const MapSelection({required this.name, required this.source});

  String get displayName {
    return name
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String get sourceLabel => source == MapSource.asset ? 'Built-in' : 'Saved';

  String get sourceQueryValue => source.name;

  static MapSource sourceFromQuery(String? value) {
    return value == MapSource.saved.name ? MapSource.saved : MapSource.asset;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapSelection && other.name == name && other.source == source;

  @override
  int get hashCode => Object.hash(name, source);
}
