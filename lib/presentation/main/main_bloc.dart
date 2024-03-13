import 'package:image_picker/image_picker.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/repositories/meme_repository.dart';

class MainBloc {
  Stream<List<Meme>> observeMemes() => MemeRepository.getInstance().observe();

  Future<String?> selectMemePhoto() async {
    final xfile = await ImagePicker().pickImage(source: ImageSource.gallery);
    return xfile?.path;
  }

  void dispose() {
    //
  }
}
