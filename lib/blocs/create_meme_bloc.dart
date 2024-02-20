// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';

class CreateMemeBloc {
  final memeTextsSubject = BehaviorSubject<List<MemeText>>.seeded([]);
  final selectedSubject = BehaviorSubject<MemeText?>();

  Stream<List<MemeText>> observeMemeTexts() =>
      memeTextsSubject.distinct((previous, next) => listEquals(previous, next));
  Stream<MemeText?> observeSelected() => selectedSubject.distinct();

  void addText() {
    final meme = MemeText.create();
    memeTextsSubject.add([...memeTextsSubject.value, meme]);
    selectedSubject.add(meme);
  }

  void changeText(final String id, final String text) {
    final list = [...memeTextsSubject.value];
    final index = list.indexWhere((e) => e.id == id);
    if (index < 0) return;
    list
      ..removeAt(index)
      ..insert(index, MemeText(id: id, text: text));
    memeTextsSubject.add(list);
  }

  void selectText(final String id) {
    final existing = memeTextsSubject.value.firstWhereOrNull((e) => e.id == id);
    selectedSubject.add(existing);
  }

  void deselectText() {
    selectedSubject.add(null);
  }

  void dispose() {
    memeTextsSubject.close();
    selectedSubject.close();
  }
}

class MemeText {
  final String id;
  final String text;

  MemeText({required this.id, required this.text});

  factory MemeText.create() {
    return MemeText(id: const Uuid().v4(), text: '');
  }

  @override
  bool operator ==(covariant MemeText other) {
    if (identical(this, other)) return true;

    return other.id == id && other.text == text;
  }

  @override
  int get hashCode => id.hashCode ^ text.hashCode;

  @override
  String toString() => 'MemeText(id: $id, text: $text)';
}
