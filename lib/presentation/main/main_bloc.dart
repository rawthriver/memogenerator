import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/repositories/meme_repository.dart';
import 'package:rxdart/rxdart.dart';

class MainBloc {
  Stream<List<Meme>> observeMemes() => MemeRepository.getInstance().observe();

  void dispose() {
    //
  }
}
