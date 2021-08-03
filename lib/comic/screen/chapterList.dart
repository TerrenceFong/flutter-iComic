import 'dart:io';

import 'package:flutter/material.dart';
import 'package:my_app/comic/utils/sqflite_db.dart';
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

    await getInfoDB();

    setState(() {
      chapterList = _items;
    });
  }

  Future<void> getInfoDB() async {
    SqfliteManager db = await SqfliteManager.getInstance();
    List<Map<String, dynamic>> resDB = await db.query(
      SqfliteManager.comicTable,
      where: 'comicName = ?',
      whereArgs: [comicPath],
    );

    Map<String, int> _chapterPage = {};
    print('resDB: $resDB');
    for (var i = 0; i < resDB.length; i++) {
      var e = resDB[i];
      _chapterPage[e['chapter']] = int.parse(e['imgPage']);
    }
    setState(() {
      chapterPage = _chapterPage;
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
        // Add a key to the ListView. This makes it possible to
        // find the list and scroll through it in the tests.
        key: const Key('long_list'),
        itemCount: chapterList.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.folder),
            title: Text(
              chapterList[index]['name']!,
              // Add a key to the Text widget for each item. This makes
              // it possible to look for a particular item in the list
              // and verify that the text is correct
              key: Key('item_${index}_text'),
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return Container(
                    child: SafeArea(
                      child: Wrap(
                        children: <Widget>[
                          ListTile(
                            title: Center(
                              child: Text('从头开始阅读'),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(
                                context,
                                '/imageList/$comicPath/${chapterList[index]["name"]}/1',
                              ).then((value) => getInfoDB());
                            },
                          ),
                          chapterPage[chapterList[index]["name"]] != null
                              ? ListTile(
                                  title: Center(
                                    child: Text(
                                      '继续阅读（从第${chapterPage[chapterList[index]["name"]]}页开始）',
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.pushNamed(
                                      context,
                                      '/imageList/$comicPath/${chapterList[index]["name"]}/${chapterPage[chapterList[index]["name"]]}',
                                    ).then((value) => getInfoDB());
                                  },
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
