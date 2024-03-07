// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/models/position.dart';
import 'package:memogenerator/data/models/text_with_position.dart';
import 'package:memogenerator/data/repositories/meme_repository.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_offset.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_state.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text.dart';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

class CreateMemeBloc {
  final memeTextsSubject = BehaviorSubject<List<MemeText>>.seeded([]);
  final selectedSubject = BehaviorSubject<MemeText?>();
  final stateSubject = BehaviorSubject<MemeState>.seeded(MemeState.empty());
  final offsetSubject = BehaviorSubject<List<MemeTextOffset>>.seeded([]);
  final offsetDebouncerSubject = BehaviorSubject<MemeTextOffset?>.seeded(null);

  Stream<List<MemeText>> observeMemeTexts() =>
      memeTextsSubject.distinct((previous, next) => listEquals(previous, next));
  Stream<MemeText?> observeSelected() => selectedSubject.distinct();
  Stream<MemeState> observeState() => stateSubject;

  StreamSubscription<MemeTextOffset?>? offsetDebouncerSubscription;
  StreamSubscription<bool>? saveSubscription;

  final String id = const Uuid().v4();

  CreateMemeBloc() {
    _createStateListener();
    _createOffsetDebouncer();
  }

  void _createStateListener() {
    Rx.combineLatest2(
      observeMemeTexts(),
      observeSelected(),
      (list, selected) => MemeState(list: list, selected: selected),
    ).listen((state) {
      stateSubject.add(state);
    });
  }

  void _createOffsetDebouncer() {
    offsetDebouncerSubscription = offsetDebouncerSubject.debounceTime(const Duration(milliseconds: 300)).listen(
      (offset) {
        if (offset != null) _changeOffset(offset);
      },
      onError: print,
    );
  }

  void save() {
    final offsets = offsetSubject.value;
    final meme = Meme(
      id: id,
      texts: memeTextsSubject.value.map((e) {
        final offset = offsets.where((element) => element.id == e.id).firstOrNull;
        return TextWithPosition(
          id: e.id,
          text: e.text,
          position: Position(
            left: offset?.offset.dx ?? 0,
            top: offset?.offset.dy ?? 0,
          ),
        );
      }).toList(),
    );
    // ensure stream will be closed
    saveSubscription = MemeRepository.getInstance().add(meme).asStream().listen((_) {}, onError: print);
  }

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

  void changeOffset(final String id, final Offset offset) {
    offsetDebouncerSubject.add(MemeTextOffset(id: id, offset: offset));
  }

  void _changeOffset(final MemeTextOffset offset) {
    final list = [...offsetSubject.value];
    list.removeWhere((element) => element.id == offset.id);
    list.add(offset);
    offsetSubject.add(list);
  }

  void dispose() {
    offsetDebouncerSubscription?.cancel();
    saveSubscription?.cancel();

    memeTextsSubject.close();
    selectedSubject.close();
    stateSubject.close();
    offsetSubject.close();
    offsetDebouncerSubject.close();
  }
}
