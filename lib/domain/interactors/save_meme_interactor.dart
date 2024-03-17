import 'dart:io';

import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/models/text_with_position.dart';
import 'package:memogenerator/data/repositories/meme_repository.dart';
import 'package:path_provider/path_provider.dart';

class SaveMemeInteractor {
  static SaveMemeInteractor? _instance;

  factory SaveMemeInteractor.getInstance() => _instance ??= SaveMemeInteractor._();

  SaveMemeInteractor._();

  Future<bool> saveMeme({
    required final String id,
    required final List<TextWithPosition> texts,
    final String? photo,
  }) async {
    var currentPath = photo;
    if (currentPath != null) {
      final docs = await getApplicationDocumentsDirectory();
      final memesPath = '${docs.absolute.path}${Platform.pathSeparator}memes';
      await Directory(memesPath).create();
      final fileName = currentPath.split(Platform.pathSeparator).last;
      var savePath = '$memesPath${Platform.pathSeparator}$fileName';

      if (await File(savePath).exists()) {
        final existingLength = await File(currentPath).length();
        final saveLength = await File(savePath).length();
        if (existingLength == saveLength) {
          currentPath = savePath;
        } else {
          final a = fileName.split('_');
          var index = int.tryParse(a.last);
          if (index != null) {
            a.removeLast();
            index++;
          } else {
            index = 1;
          }
          a.add('$index');
          savePath = '$memesPath${Platform.pathSeparator}${a.join('_')}';
        }
      }

      if (currentPath != savePath) {
        await File(currentPath).copy(savePath);
        currentPath = savePath;
        // memePhotoSubject.add(currentPath);
      }
    }
    final meme = Meme(
      id: id,
      texts: texts,
      photo: currentPath,
    );
    return MemeRepository.getInstance().add(meme);
  }
}
