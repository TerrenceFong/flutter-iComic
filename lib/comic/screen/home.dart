import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String comicPath = '';
  List<Map<String, String>> comicList = [];

  @override
  void initState() {
    super.initState();
    print('initstate1');

    getRootInfo();
  }

  Future<String> localPath() async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<void> getRootInfo() async {
    final path = await localPath();

    final dir = Directory('$path');
    print(dir);

    final List<Map<String, String>> _items = [];

    await for (var entity in dir.list(followLinks: false)) {
      final isDir = await FileSystemEntity.isDirectory(entity.path);
      final dirname = p.basename(entity.path);
      if (isDir == true) {
        _items.add({'name': dirname, 'path': entity.path});
      }
    }

    setState(() {
      comicPath = path;
      comicList = _items;
    });
    // return File('$path/test.png');
  }

  @override
  Widget build(BuildContext context) {
    print('build');
    return Scaffold(
      appBar: AppBar(
        title: Text('Comic Lists'),
      ),
      body: ListView.builder(
        // Add a key to the ListView. This makes it possible to
        // find the list and scroll through it in the tests.
        key: const Key('long_list'),
        itemCount: comicList.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.folder),
            title: Text(
              comicList[index]['name']!,
              // Add a key to the Text widget for each item. This makes
              // it possible to look for a particular item in the list
              // and verify that the text is correct
              key: Key('item_${index}_text'),
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/imageList/${comicList[index]["name"]}',
              );
            },
          );
        },
      ),
    );
  }
}
