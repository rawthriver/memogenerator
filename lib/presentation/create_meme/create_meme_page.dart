import 'dart:io';

import 'package:flutter/material.dart';
import 'package:memogenerator/presentation/create_meme/create_meme_bloc.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_selection.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_offset.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';

class CreateMemePage extends StatefulWidget {
  final String? id;
  final String? photo;

  const CreateMemePage({super.key, this.id, this.photo});

  @override
  State<CreateMemePage> createState() => _CreateMemePageState();
}

class _CreateMemePageState extends State<CreateMemePage> {
  late final CreateMemeBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = CreateMemeBloc(id: widget.id, photo: widget.photo);
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Создаём мем'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: const Icon(Icons.save_outlined),
                onPressed: bloc.save,
              ),
            )
          ],
          backgroundColor: AppColors.lemon,
          foregroundColor: AppColors.grey,
          bottom: const EditTextBar(),
        ),
        backgroundColor: Colors.white,
        body: const SafeArea(
          child: CreateMemePageContent(),
        ),
        resizeToAvoidBottomInset: false,
      ),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }
}

class EditTextBar extends StatefulWidget implements PreferredSizeWidget {
  const EditTextBar({super.key});

  @override
  State<EditTextBar> createState() => _EditTextBarState();

  @override
  Size get preferredSize => const Size.fromHeight(68);
}

class _EditTextBarState extends State<EditTextBar> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focus = FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: StreamBuilder<MemeText?>(
        stream: bloc.observeSelected(),
        builder: (context, snapshot) {
          final meme = snapshot.hasData ? snapshot.data : null;
          final text = meme?.text ?? '';
          if (text != _controller.text) {
            _controller.text = text;
            _controller.selection = TextSelection.collapsed(offset: text.length);
          }
          final isSelected = meme != null;
          if (isSelected) _focus.requestFocus();
          return TextField(
            enabled: isSelected,
            controller: _controller,
            focusNode: _focus,
            onChanged: (value) {
              if (isSelected) bloc.changeText(meme.id, value);
            },
            onEditingComplete: bloc.deselectText,
            // onTapOutside: Fx.unFocus,
            decoration: InputDecoration(
              filled: true,
              fillColor: isSelected ? AppColors.fuchsia16 : AppColors.grey6,
              border: UnderlineInputBorder(
                  borderSide: BorderSide(color: isSelected ? AppColors.fuchsia38 : AppColors.grey38)),
              focusColor: AppColors.fuchsia16,
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.fuchsia, width: 2)),
              hintText: isSelected ? 'Введите текст' : null,
              hintStyle: TextStyle(fontSize: 16, color: AppColors.grey38),
            ),
            cursorColor: AppColors.fuchsia,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }
}

class CreateMemePageContent extends StatefulWidget {
  const CreateMemePageContent({super.key});

  @override
  State<CreateMemePageContent> createState() => _CreateMemePageContentState();
}

class _CreateMemePageContentState extends State<CreateMemePageContent> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(
          flex: 2,
          child: MemeCanvasWidget(),
        ),
        Container(
          height: 1,
          color: AppColors.grey,
        ),
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.white,
            child: const BottomMemeList(),
          ),
        ),
      ],
    );
  }
}

class MemeCanvasWidget extends StatelessWidget {
  const MemeCanvasWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return Container(
      padding: const EdgeInsets.all(8),
      color: AppColors.grey38,
      alignment: Alignment.center,
      child: AspectRatio(
        aspectRatio: 1,
        child: GestureDetector(
          onTap: () => bloc.deselectText(),
          child: Stack(
            children: [
              StreamBuilder(
                stream: bloc.observeMemePhoto(),
                builder: (context, snapshot) {
                  final photo = snapshot.data;
                  if (photo == null) {
                    return Container(color: Colors.white);
                  }
                  return Container(
                    color: Colors.white,
                    height: double.infinity,
                    child: Image.file(
                      File(photo),
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
              StreamBuilder(
                stream: bloc.observeMemeTextsWithOffset(),
                initialData: const <MemeTextWithOffset>[],
                builder: (context, snapshot) {
                  final list = snapshot.hasData ? snapshot.data! : const <MemeTextWithOffset>[];
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: list.map((text) {
                          return MemeTextWidget(text: text, box: constraints);
                        }).toList(),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MemeTextWidget extends StatefulWidget {
  final MemeTextWithOffset text;
  final BoxConstraints box;

  const MemeTextWidget({
    super.key,
    required this.text,
    required this.box,
  });

  @override
  State<MemeTextWidget> createState() => _MemeTextWidgetState();
}

class _MemeTextWidgetState extends State<MemeTextWidget> {
  static const double padding = 8;
  static const double line = 24;

  late double left;
  late double top;

  @override
  void initState() {
    super.initState();
    left = widget.text.offset?.dx ?? widget.box.maxWidth / 3;
    top = widget.text.offset?.dy ?? widget.box.maxHeight / 2 - padding * 2 - line;
  }

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => bloc.selectText(widget.text.id),
        onPanUpdate: (details) {
          setState(() {
            left = calculateLeft(details);
            top = calculateTop(details);
            bloc.changeOffset(widget.text.id, Offset(left, top));
          });
        },
        onPanStart: (_) => bloc.selectText(widget.text.id),
        child: StreamBuilder<MemeText?>(
          stream: bloc.observeSelected(),
          builder: (context, snapshot) {
            final text = snapshot.hasData ? snapshot.data : null;
            final selected = widget.text.id == text?.id;
            return MemeTextCanvas(
              padding: padding,
              text: widget.text.text,
              box: widget.box,
              selected: selected,
            );
          },
        ),
      ),
    );
  }

  double calculateLeft(DragUpdateDetails details) {
    final l = left + details.delta.dx;
    if (l < 0) return 0;
    final w = widget.box.maxWidth - padding * 2 - line * 2;
    return l > w ? w : l;
  }

  double calculateTop(DragUpdateDetails details) {
    final t = top + details.delta.dy;
    if (t < 0) return 0;
    final h = widget.box.maxHeight - padding * 2 - line;
    return t > h ? h : t;
  }
}

class MemeTextCanvas extends StatelessWidget {
  final double padding;
  final BoxConstraints box;
  final String text;
  final bool selected;

  const MemeTextCanvas({
    super.key,
    required this.padding,
    required this.box,
    required this.text,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: box.maxWidth,
        maxHeight: box.maxHeight,
      ),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: selected ? AppColors.grey16 : null,
        border: Border.all(color: selected ? AppColors.fuchsia : Colors.transparent),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 20,
          color: AppColors.grey,
        ),
      ),
    );
  }
}

class BottomMemeList extends StatelessWidget {
  const BottomMemeList({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return StreamBuilder(
      stream: bloc.observeMemeTextsWithSelection(),
      initialData: const <MemeTextWithSelection>[],
      builder: (context, snapshot) {
        final list = snapshot.hasData ? snapshot.data! : const <MemeTextWithSelection>[];
        return ListView.separated(
          itemBuilder: (context, index) {
            if (index == 0) return const AddMemeTextButton();
            final item = list[index - 1];
            return Container(
              height: 48,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: item.selected ? AppColors.grey16 : null,
              child: Text(
                item.text.text,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.grey,
                ),
              ),
            );
          },
          separatorBuilder: (context, index) => index == 0
              ? const SizedBox.shrink()
              : Container(margin: const EdgeInsets.only(left: 16), color: AppColors.grey, height: 1),
          itemCount: list.length + 1,
        );
      },
    );
  }
}

class AddMemeTextButton extends StatelessWidget {
  const AddMemeTextButton({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => bloc.addText(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add,
              color: AppColors.fuchsia,
            ),
            const SizedBox(width: 8),
            Text(
              'Добавить текст'.toUpperCase(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.25,
                color: AppColors.fuchsia,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
