import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/shared_preferences_storage.dart';

class MemeRepository {
  final SharedPreferencesStorage _storage;
  final _updater = PublishSubject<Null>();

  static MemeRepository? _instance;
  factory MemeRepository.getInstance() => _instance ??= MemeRepository._(SharedPreferencesStorage.getInstance());
  MemeRepository._(this._storage);

  Future<bool> add(final Meme meme) async {
    final list = await getList();
    int i = list.indexWhere((e) => e.id == meme.id);
    if (i < 0) {
      list.add(meme);
    } else {
      list.removeAt(i);
      list.insert(i, meme);
    }
    return _setList(list);
  }

  Future<bool> remove(final String id) async {
    final list = await getList();
    list.removeWhere((e) => e.id == id);
    return _setList(list);
  }

  Future<Meme?> get(final String id) async {
    final list = await getList();
    return list.where((e) => e.id == id).firstOrNull;
  }

  Stream<List<Meme>> observe() async* {
    yield await getList();
    await for (final _ in _updater) {
      yield await getList();
    }
  }

  Future<List<Meme>> getList() async {
    final raw = await _storage.getMemes();
    return raw.map((e) => Meme.fromJson(e)).toList();
  }

  Future<bool> _setList(final List<Meme> list) async {
    final raw = list.map((e) => e.toJson()).toList();
    return _setRaw(raw);
  }

  Future<bool> _setRaw(final List<String> raw) async {
    final result = await _storage.setMemes(raw);
    if (result) _updater.add(null);
    return Future.value(result);
  }
}
