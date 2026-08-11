enum UnitMovementDomain {
  land,
  naval,
  air;

  bool get isNaval => this == UnitMovementDomain.naval;
}
