// Family member model for genogram visualization
import 'package:flutter/material.dart';

class FamilyMember {
  final String id;
  final String name;
  final String? fatherId; // Father's ID
  final String? motherId; // Mother's ID
  final DateTime? dateOfBirth;
  final DateTime? dateOfDeath;
  final int gender;
  final List<String> spouses; // IDs of relationships
  final Map<String, dynamic> extraData; // Additional data like medical info
  final Color color;
  bool isDeceased;
  FamilyMember({
    required this.id,
    required this.name,
    this.fatherId,
    this.motherId,
    this.dateOfBirth,
    this.dateOfDeath,
    required this.gender,
    List<String>? spouses,
    Map<String, dynamic>? extraData,
    Color? color,
    this.isDeceased = false,
  })  : spouses = spouses ?? [],
        extraData = extraData ?? {},
        color = color ?? Colors.blue;
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'fatherId': fatherId,
      'motherId': motherId,
      'dateOfBirth': dateOfBirth?.toString(),
      'dateOfDeath': dateOfDeath?.toString(),
      'gender': gender.toString(),
      'relationships': spouses,
      'extraData': extraData,
      'color': color.value,
      'isDeceased': isDeceased,
    };
  }

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'],
      name: map['name'],
      fatherId: map['fatherId'],
      motherId: map['motherId'],
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.parse(map['dateOfBirth'])
          : null,
      dateOfDeath: map['dateOfDeath'] != null
          ? DateTime.parse(map['dateOfDeath'])
          : null,
      gender: map['gender'],
      spouses: List<String>.from(map['spouses'] ?? []),
      extraData: Map<String, dynamic>.from(map['extraData'] ?? {}),
      color: Color(map['color'] ?? Colors.blue.value),
      isDeceased: map['isDeceased'] ?? false,
    );
  }
  FamilyMember copyWith({
    String? id,
    String? name,
    String? fatherId,
    String? motherId,
    DateTime? dateOfBirth,
    DateTime? dateOfDeath,
    int? gender,
    List<String>? spouses,
    Map<String, dynamic>? extraData,
    Color? color,
    bool? isDeceased,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      fatherId: fatherId ?? this.fatherId,
      motherId: motherId ?? this.motherId,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      dateOfDeath: dateOfDeath ?? this.dateOfDeath,
      gender: gender ?? this.gender,
      spouses: spouses ?? List.from(this.spouses),
      extraData: extraData ?? Map.from(this.extraData),
      color: color ?? this.color,
      isDeceased: isDeceased ?? this.isDeceased,
    );
  }
}
