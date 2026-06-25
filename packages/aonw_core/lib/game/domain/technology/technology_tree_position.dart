class TechnologyTreePosition {
  final int column;
  final int row;

  const TechnologyTreePosition({required this.column, required this.row});

  @override
  bool operator ==(Object other) =>
      other is TechnologyTreePosition &&
      other.column == column &&
      other.row == row;

  @override
  int get hashCode => Object.hash(column, row);
}
