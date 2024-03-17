import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/repositories/meme_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

///
/// 3. При вызове метода addMeme в memesRepository заменять мем, если он уже
///    есть в списке
///    Обязательное, 1 балл
///    1. В случае если у нас уже сохранен мем с таким же id, как мы пытаемся
///       сохранить, удалять старый мем и на его место вставлять новый
///    2. Сохранять индекс мема, если он уже был сохранен
///    3. Добавлять мем в конец, если до этого такого мема не было в списке
///
void runTestLesson2Task3() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets('module3', (WidgetTester tester) async {
    print("\n------------- Запускаем тест к 3 заданию 10-го урока -------------\n");

    SharedPreferences.setMockInitialValues({"meme_key": []});

    final firstMeme = Meme(id: Uuid().v4(), texts: [], photo: "first.jpg");
    final secondMeme = Meme(id: Uuid().v4(), texts: [], photo: "second.jpg");
    final thirdMeme = Meme(id: Uuid().v4(), texts: [], photo: "third.jpg");

    final memesRepository = MemeRepository.getInstance();

    print("Добавляем в MemesRepository два объекта с мемами ($firstMeme и $secondMeme) используя метод addToMemes");
    await memesRepository.add(firstMeme);
    await memesRepository.add(secondMeme);

    print("Проверяем, что оба объекта успешно сохранены");
    expect(
      await memesRepository.getList(),
      [firstMeme, secondMeme],
      reason: "ОШИБКА! Мемы сохранены неверно",
    );

    print("Добавляем в MemesRepository новый мем $thirdMeme");
    await memesRepository.add(thirdMeme);

    print("Проверяем, что все мемы сохранены в нужной последовательности");
    expect(
      await memesRepository.getList(),
      [firstMeme, secondMeme, thirdMeme],
      reason: "ОШИБКА! Мемы сохранены неверно",
    );

    final changedSecondMeme = Meme(id: secondMeme.id, texts: [], photo: "changedSecond.jpg");

    print("Добавляем новый мем с тем же id, что и у второго мема, но с другим названием картинки: $changedSecondMeme");
    await memesRepository.add(changedSecondMeme);

    print(
        "Проверяем, что старый мем с id ${secondMeme.id} убран и вместо него на той же позиции находится новый мем $changedSecondMeme");
    expect(
      await memesRepository.getList(),
      [firstMeme, changedSecondMeme, thirdMeme],
      reason: "ОШИБКА! Мемы сохранены неверно",
    );

    print("------------- УСПЕХ! Тест пройден! -------------\n");
  });
}
