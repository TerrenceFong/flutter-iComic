import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import "package:collection/collection.dart";

class ChapterList extends StatefulWidget {
  final String comicPath;

  const ChapterList({Key? key, required this.comicPath}) : super(key: key);

  @override
  _ChapterListState createState() => _ChapterListState(comicPath);
}

class _ChapterListState extends State<ChapterList> {
  final String comicPath;
  List<Map<String, String>> chapterList = [];

  Map<String, int> chapterPage = {};

  _ChapterListState(this.comicPath);

  @override
  void initState() {
    super.initState();
    print('chapterList');

    getChapterInfo();
  }

  Future<String> localPath() async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<void> getChapterInfo() async {
    final path = await localPath();

    final dir = Directory('$path/$comicPath');
    print('comic: $dir');

    List<Map<String, String>> _items = [];

    await for (FileSystemEntity entity in dir.list(followLinks: false)) {
      final isDir = await FileSystemEntity.isDirectory(entity.path);
      final dirname = p.basename(entity.path);

      if (isDir == true) {
        _items.add({'name': dirname, 'path': entity.path});
      }
    }

    _items.sort((a, b) => compareAsciiUpperCase(a['name']!, b['name']!));

    setState(() {
      chapterList = _items;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('build');
    return Scaffold(
      appBar: AppBar(
        title: Text(comicPath),
      ),
      body: ListView.builder(
        key: const Key('long_list'),
        itemCount: chapterList.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.folder),
            title: Text(
              chapterList[index]['name']!,
              key: Key('item_${index}_text'),
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/previewList/$comicPath/${chapterList[index]["name"]}',
              );
            },
          );
        },
      ),
    );
  }
}
