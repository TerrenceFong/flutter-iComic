import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:my_app/comic/utils/sqflite_db.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PreviewList extends StatefulWidget {
  final String path;

  const PreviewList({Key? key, required this.path}) : super(key: key);

  @override
  _PreviewListState createState() => _PreviewListState(path);
}

class _PreviewListState extends State<PreviewList> {
  final String path;

  List<String> imageData = [];
  Map<String, int> chapterPage = {};
  String comicName = '';
  String chapter = '';

  double screenWidth = window.physicalSize.width / window.devicePixelRatio;

  late Offset pointerStart;
  late Offset pointerEnd;
  double touchRangeX = 0;
  double nextOffset = 0;
  int lastPage = 0;

  _PreviewListState(this.path);

  @override
  void initState() {
    super.initState();
    print('previewList');

    getImageInfo();
  }

  Future<String> localPath() async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<void> getImageInfo() async {
    final rootPath = await localPath();

    final dir = Directory('$rootPath/$path');

    final List<String> _imageData = [];

    await for (FileSystemEntity entity
        in dir.list(recursive: true, followLinks: false)) {
      _imageData.add(entity.path);
    }

    _imageData.sort();

    List<String> pathList = path.split('/');
    String _comicName = pathList[0];
    String _chapter = pathList[1];

    setState(() {
      comicName = _comicName;
      chapter = _chapter;

      imageData = _imageData;

      getInfoDB();
    });
  }

  Future<void> getInfoDB() async {
    SqfliteManager db = await SqfliteManager.getInstance();
    List<Map<String, dynamic>> resDB = await db.query(
      SqfliteManager.comicTable,
      where: 'comicName = ?',
      whereArgs: [comicName],
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
    print('previewList build');

    return Scaffold(
      appBar: AppBar(
        title: Text(chapter),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.settings,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/setting',
              );
            },
          )
        ],
      ),
      body: ListView.builder(
        itemCount: imageData.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(p.basename(imageData[index])),
            subtitle: chapterPage[chapter] == null
                ? Row(
                    children: [
                      Icon(
                        Icons.circle_rounded,
                        color: Colors.blue,
                        size: 14,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Icon(
                        Icons.circle_outlined,
                        color: Colors.blue,
                        size: 14,
                      ),
                      Container(
                        child:
                            Text('${chapterPage[chapter]}/${imageData.length}'),
                        margin: const EdgeInsets.only(left: 8),
                      ),
                    ],
                  ),
            leading: Image.file(File(imageData[index])),
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
                              child: Text('打开已选中的图像'),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(
                                context,
                                '/imageList/$comicName/$chapter/${index + 1}',
                              ).then((value) => getInfoDB());
                            },
                          ),
                          chapterPage[chapter] != null
                              ? ListTile(
                                  title: Center(
                                    child: Text(
                                      '继续阅读（从第${chapterPage[chapter]}页开始）',
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.pushNamed(
                                      context,
                                      '/imageList/$comicName/$chapter/${chapterPage[chapter]}',
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
