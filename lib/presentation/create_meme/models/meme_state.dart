// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';

import 'package:memogenerator/presentation/create_meme/models/meme_text.dart';

class MemeState extends Equatable {
  final List<MemeText> list;
  final MemeText? selected;

  const MemeState({
    required this.list,
    required this.selected,
  });

  factory MemeState.empty() => const MemeState(list: [], selected: null);

  @override
  List<Object?> get props => [list, selected];
}
