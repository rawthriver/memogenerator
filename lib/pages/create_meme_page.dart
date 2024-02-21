import 'package:flutter/material.dart';
import 'package:flutter_utils/flutter_utils.dart';
import 'package:memogenerator/blocs/create_meme_bloc.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';

class CreateMemePage extends StatefulWidget {
  const CreateMemePage({super.key});

  @override
  State<CreateMemePage> createState() => _CreateMemePageState();
}

class _CreateMemePageState extends State<CreateMemePage> {
  late final CreateMemeBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = CreateMemeBloc();
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Создаём мем'),
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
            final meme = Fx.validateStreamData(snapshot) ? snapshot.data : null;
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
              // onTapOutside: (_) => Fx.unFocus(),
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
          }),
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

class BottomMemeList extends StatelessWidget {
  const BottomMemeList({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return StreamBuilder(
      stream: bloc.observeState(),
      builder: (context, snapshot) {
        final state = Fx.validateStreamData(snapshot) ? snapshot.data : null;
        if (state == null) return const SizedBox.shrink();
        return ListView.separated(
          itemBuilder: (context, index) {
            if (index == 0) return const AddMemeTextButton();
            return Container(
              height: 48,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: state.selected?.id == state.list[index - 1].id ? AppColors.grey16 : null,
              child: Text(
                state.list[index - 1].text,
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
          itemCount: state.list.length + 1,
        );
      },
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
          child: StreamBuilder(
            stream: bloc.observeState(),
            builder: (context, snapshot) {
              final state = Fx.validateStreamData(snapshot) ? snapshot.data : null;
              if (state == null) return const SizedBox.shrink();
              return Container(
                color: Colors.white,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: state.list.map((meme) {
                        return MemeTextWidget(meme: meme, box: constraints, isSelected: state.selected?.id == meme.id);
                      }).toList(),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class MemeTextWidget extends StatefulWidget {
  final MemeText meme;
  final BoxConstraints box;
  final bool isSelected;

  const MemeTextWidget({
    super.key,
    required this.meme,
    required this.box,
    required this.isSelected,
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
    left = widget.box.maxWidth / 3;
    top = widget.box.maxHeight / 2 - padding * 2 - line;
  }

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => bloc.selectText(widget.meme.id),
        onPanUpdate: (details) => setState(() {
          left = calculateLeft(details);
          top = calculateTop(details);
        }),
        onPanStart: (_) => bloc.selectText(widget.meme.id),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: widget.box.maxWidth,
            maxHeight: widget.box.maxHeight,
          ),
          padding: const EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: widget.isSelected ? AppColors.grey16 : null,
            border: Border.all(color: widget.isSelected ? AppColors.fuchsia : Colors.transparent),
          ),
          child: Text(
            widget.meme.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              color: AppColors.grey,
            ),
          ),
        ),
      ),
    );
  }

  double calculateTop(DragUpdateDetails details) {
    final t = top + details.delta.dy;
    if (t < 0) return 0;
    final h = widget.box.maxHeight - padding * 2 - line;
    return t > h ? h : t;
  }

  double calculateLeft(DragUpdateDetails details) {
    final l = left + details.delta.dx;
    if (l < 0) return 0;
    final w = widget.box.maxWidth - padding * 2 - line * 2;
    return l > w ? w : l;
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
