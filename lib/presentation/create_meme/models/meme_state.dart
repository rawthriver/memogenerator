// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';

import 'package:memogenerator/presentation/create_meme/models/meme_text.dart';

class MemeTextWithSelection extends Equatable {
  final MemeText text;
  final bool selected;

  const MemeTextWithSelection({
    required this.text,
    required this.selected,
  });

  @override
  List<Object?> get props => [text, selected];
}
