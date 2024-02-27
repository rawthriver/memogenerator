// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class Position extends Equatable {
  final double left;
  final double top;

  const Position({
    required this.left,
    required this.top,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'left': left,
      'top': top,
    };
  }

  factory Position.fromMap(Map<String, dynamic> map) {
    return Position(
      left: map['left'] as double,
      top: map['top'] as double,
    );
  }

  String toJson() => json.encode(toMap());

  factory Position.fromJson(String source) => Position.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object> get props => [left, top];
}
