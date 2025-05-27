// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class Unit extends Equatable {
  final String id;
  final DateTime createdAt;
  final String name;
  final String abbreviation;
  final String? category;
  final String? description;

  const Unit({
    required this.id,
    required this.createdAt,
    required this.name,
    required this.abbreviation,
    this.category,
    this.description,
  });

  Unit copyWith({
    String? id,
    DateTime? createdAt,
    String? name,
    String? abbreviation,
    String? category,
    String? description,
  }) {
    return Unit(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      abbreviation: abbreviation ?? this.abbreviation,
      category: category ?? this.category,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'name': name,
      'abbreviation': abbreviation,
      'category': category,
      'description': description,
    };
  }

  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      name: map['name'] as String,
      abbreviation: map['abbreviation'] as String,
      category: map['category'] != null ? map['category'] as String : null,
      description:
          map['description'] != null ? map['description'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Unit.fromJson(String source) =>
      Unit.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Unit(id: $id, createdAt: $createdAt, name: $name, abbreviation: $abbreviation, category: $category, description: $description)';
  }

  @override
  List<Object?> get props => [
    id,
    createdAt,
    name,
    abbreviation,
    category,
    description,
  ];
}
