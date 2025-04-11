// enum Gender {unknown, male, female}

class FamilyMember {
  final String id;
  final String? name;
  final String? fatherId;
  final String? motherId;
  final List<String>? spouses;

  // Genogram-specific properties
  final int gender;
  final bool isDeceased;
  final DateTime? birthDate;
  final DateTime? deathDate;

  FamilyMember({
    required this.id,
    required this.gender,
    this.name,
    this.fatherId,
    this.motherId,
    this.spouses,
    this.isDeceased = false,
    this.birthDate,
    this.deathDate,
  });
  @override
  String toString() {
    return 'FM(id: $id, name: $name, gender: $gender, fatherId: $fatherId, motherId: $motherId, spouses: $spouses)';
  }
}

/// Gender enumeration for family members
// enum Gender {
//   male,
//   female,
//   unknown
// }

/// Birth type to indicate twins or other multiple births
// enum BirthType {
//   single,
//   identical, // Identical twins
//   fraternal, // Fraternal twins
//   multiple  // For triplets or more
// }

/// Relationship type between spouses
// enum RelationshipType {
//   married,
//   divorced,
//   separated,
//   cohabiting,
//   engaged
// }
