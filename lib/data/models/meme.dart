// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:memogenerator/data/models/text_with_position.dart';

class Meme extends Equatable {
  final String id;
  final List<TextWithPosition> texts;
  final String? photo;

  const Meme({required this.id, required this.texts, this.photo});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'texts': texts.map((x) => x.toMap()).toList(),
      'photo': photo,
    };
  }

  factory Meme.fromMap(Map<String, dynamic> map) {
    return Meme(
      id: map['id'] as String,
      texts: List<TextWithPosition>.from(
        (map['texts'] as List).map<TextWithPosition>(
          (x) => TextWithPosition.fromMap(x as Map<String, dynamic>),
        ),
      ),
      photo: map['photo'] != null ? map['photo'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Meme.fromJson(String source) => Meme.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [id, texts, photo];
}
