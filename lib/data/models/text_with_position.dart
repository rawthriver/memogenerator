// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:memogenerator/data/models/position.dart';

class TextWithPosition extends Equatable {
  final String id;
  final String text;
  final Position position;

  const TextWithPosition({
    required this.id,
    required this.text,
    required this.position,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'text': text,
      'position': position.toMap(),
    };
  }

  factory TextWithPosition.fromMap(Map<String, dynamic> map) {
    return TextWithPosition(
      id: map['id'] as String,
      text: map['text'] as String,
      position: Position.fromMap(map['position'] as Map<String, dynamic>),
    );
  }

  String toJson() => json.encode(toMap());

  factory TextWithPosition.fromJson(String source) =>
      TextWithPosition.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object> get props => [id, text, position];
}
