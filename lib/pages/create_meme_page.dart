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
            if (meme != null) _focus.requestFocus();
            return TextField(
              enabled: meme != null,
              controller: _controller,
              focusNode: _focus,
              onChanged: (value) {
                if (meme != null) bloc.changeText(meme.id, value);
              },
              onEditingComplete: bloc.deselectText,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.grey6,
              ),
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
            child: ListView(
              children: [
                const AddMemeTextButton(),
              ],
            ),
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
        child: Container(
          color: Colors.white,
          child: StreamBuilder<List<MemeText>>(
              stream: bloc.observeMemeTexts(),
              initialData: const [],
              builder: (context, snapshot) {
                final list = Fx.validateStreamData(snapshot) ? snapshot.data! : const [];
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: list.map((meme) {
                        return MemeTextWidget(meme: meme, box: constraints);
                      }).toList(),
                    );
                  },
                );
              }),
        ),
      ),
    );
  }
}

class MemeTextWidget extends StatefulWidget {
  final MemeText meme;
  final BoxConstraints box;

  const MemeTextWidget({
    super.key,
    required this.meme,
    required this.box,
  });

  @override
  State<MemeTextWidget> createState() => _MemeTextWidgetState();
}

class _MemeTextWidgetState extends State<MemeTextWidget> {
  static const double padding = 8;

  double left = 0;
  double top = 0;

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
        child: Container(
          constraints: BoxConstraints(
            maxWidth: widget.box.maxWidth,
            maxHeight: widget.box.maxHeight,
          ),
          padding: const EdgeInsets.all(padding),
          color: AppColors.grey6,
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
    final h = widget.box.maxHeight - padding * 2 - 24;
    return t > h ? h : t;
  }

  double calculateLeft(DragUpdateDetails details) {
    final l = left + details.delta.dx;
    if (l < 0) return 0;
    final w = widget.box.maxWidth - padding * 2 - 48;
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
