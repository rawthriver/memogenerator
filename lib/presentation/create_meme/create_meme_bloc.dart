// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/models/position.dart';
import 'package:memogenerator/data/models/text_with_position.dart';
import 'package:memogenerator/data/repositories/meme_repository.dart';
import 'package:memogenerator/domain/interactors/save_meme_interactor.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_offset.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_selection.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_offset.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

class CreateMemeBloc {
  final memeTextsSubject = BehaviorSubject<List<MemeText>>.seeded([]);
  final selectedSubject = BehaviorSubject<MemeText?>.seeded(null);
  final offsetSubject = BehaviorSubject<List<MemeTextOffset>>.seeded([]);
  final offsetDebouncerSubject = BehaviorSubject<MemeTextOffset?>.seeded(null);
  final memePhotoSubject = BehaviorSubject<String?>.seeded(null);

  Stream<List<MemeText>> observeMemeTexts() =>
      memeTextsSubject.distinct((previous, next) => listEquals(previous, next));
  Stream<MemeText?> observeSelected() => selectedSubject.distinct();

  Stream<List<MemeTextWithSelection>> observeMemeTextsWithSelection() {
    return Rx.combineLatest2(
      observeMemeTexts(),
      observeSelected(),
      (list, selected) => list.map((e) => MemeTextWithSelection(text: e, selected: e.id == selected?.id)).toList(),
    );
  }

  Stream<List<MemeTextWithOffset>> observeMemeTextsWithOffset() {
    return Rx.combineLatest2(
      observeMemeTexts(),
      offsetSubject.distinct(),
      (texts, offsets) {
        return texts.map((t) {
          final o = offsets.firstWhereOrNull((o) => o.id == t.id);
          return MemeTextWithOffset(id: t.id, text: t.text, offset: o?.offset);
        }).toList();
      },
    ).distinct((previous, next) => listEquals(previous, next));
  }

  Stream<String?> observeMemePhoto() => memePhotoSubject.distinct();

  StreamSubscription<MemeTextOffset?>? offsetDebouncerSubscription;
  StreamSubscription<bool>? saveSubscription;
  StreamSubscription<Meme?>? loadSubscription;

  final String id;
  final String? photo;

  CreateMemeBloc({final String? id, this.photo}) : id = id ?? const Uuid().v4() {
    memePhotoSubject.add(photo);
    _createOffsetDebouncer();
    _createLoader();
  }

  void _createOffsetDebouncer() {
    offsetDebouncerSubscription = offsetDebouncerSubject.debounceTime(const Duration(milliseconds: 300)).listen(
      (offset) {
        if (offset != null) _changeOffset(offset);
      },
      onError: print,
    );
  }

  void _createLoader() {
    loadSubscription = MemeRepository.getInstance().get(id).asStream().listen(
      (meme) {
        if (meme == null) return;
        final texts = meme.texts.map((t) {
          return MemeText(id: t.id, text: t.text);
        }).toList();
        memeTextsSubject.add(texts);
        final offsets = meme.texts.map((t) {
          return MemeTextOffset(id: t.id, offset: Offset(t.position.left, t.position.top));
        }).toList();
        offsetSubject.add(offsets);
        memePhotoSubject.add(meme.photo);
      },
      onError: print,
    );
  }

  void save() {
    final offsets = offsetSubject.value;
    final texts = memeTextsSubject.value.map((e) {
      final offset = offsets.where((o) => o.id == e.id).firstOrNull;
      return TextWithPosition(
        id: e.id,
        text: e.text,
        position: Position(
          left: offset?.offset.dx ?? 0,
          top: offset?.offset.dy ?? 0,
        ),
      );
    }).toList();
    // graceful cleanup
    saveSubscription = SaveMemeInteractor.getInstance()
        .saveMeme(id, texts, memePhotoSubject.value)
        .asStream()
        .listen(null, onError: print);
  }

  // Future<bool> _save(final List<TextWithPosition> texts) async {
  //   var currentPath = memePhotoSubject.value;
  //   if (currentPath != null) {
  //     final docs = await getApplicationDocumentsDirectory();
  //     final memesPath = '${docs.absolute.path}${Platform.pathSeparator}memes';
  //     await Directory(memesPath).create();
  //     final fileName = currentPath.split(Platform.pathSeparator).last;
  //     final savePath = '$memesPath${Platform.pathSeparator}$fileName';
  //     if (currentPath != savePath) {
  //       await File(currentPath).copy(savePath);
  //       currentPath = savePath;
  //       memePhotoSubject.add(currentPath);
  //     }
  //   }
  //   final meme = Meme(
  //     id: id,
  //     texts: texts,
  //     photo: currentPath,
  //   );
  //   return MemeRepository.getInstance().add(meme);
  // }

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
    loadSubscription?.cancel();

    memeTextsSubject.close();
    selectedSubject.close();
    offsetSubject.close();
    offsetDebouncerSubject.close();
    memePhotoSubject.close();
  }
}
