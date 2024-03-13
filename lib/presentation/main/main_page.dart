import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/presentation/main/main_bloc.dart';
import 'package:memogenerator/presentation/create_meme/create_meme_page.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final MainBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = MainBloc();
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            'Мемогенератор',
            style: GoogleFonts.seymourOne(fontSize: 24),
          ),
          backgroundColor: AppColors.lemon,
          foregroundColor: AppColors.grey,
        ),
        backgroundColor: Colors.white,
        body: const SafeArea(
          child: MainPageContent(),
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: Text('Создать'.toUpperCase()),
          backgroundColor: AppColors.fuchsia,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          onPressed: () async {
            final photo = await bloc.selectMemePhoto();
            if (photo == null) return;
            if (!context.mounted) return;
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateMemePage(photo: photo)));
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }
}

class MainPageContent extends StatefulWidget {
  const MainPageContent({super.key});

  @override
  State<MainPageContent> createState() => _MainPageContentState();
}

class _MainPageContentState extends State<MainPageContent> {
  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<MainBloc>(context, listen: false);
    return StreamBuilder(
      stream: bloc.observeMemes(),
      initialData: const <Meme>[],
      builder: (context, snapshot) {
        final list = snapshot.hasData && snapshot.data != null ? snapshot.data : const <Meme>[];
        if (list == null) return const SizedBox.shrink();
        return ListView.builder(
          itemBuilder: (context, index) {
            final meme = list[index];
            return GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CreateMemePage(id: meme.id),
                ),
              ),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: Text(meme.id),
              ),
            );
          },
          itemCount: list.length,
        );
      },
    );
  }
}
