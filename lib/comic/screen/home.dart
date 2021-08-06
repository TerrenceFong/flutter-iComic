import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:i_comic/comic/common/global.dart';
import 'package:i_comic/comic/utils/sqflite_db.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import "package:collection/collection.dart";
import 'package:flutter_slidable/flutter_slidable.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Map<String, String>> comicList = [];
  GlobalKey key1 = GlobalKey();

  List<GlobalObjectKey> keyList = [];

  bool alive = false;

  @override
  void initState() {
    super.initState();
    print('comicList');

    getRootInfo();

    // 初始化数据库
    Global.init();
  }

  Future<String> localPath() async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<void> getRootInfo() async {
    final path = await localPath();

    final dir = Directory('$path');
    print('root: $dir');

    List<Map<String, String>> _items = [];

    await for (FileSystemEntity entity in dir.list(followLinks: false)) {
      final isDir = await FileSystemEntity.isDirectory(entity.path);
      final dirname = p.basename(entity.path);
      print('dirname: $dirname');
      if (isDir == true) {
        _items.add({'name': dirname, 'path': entity.path});
      }
    }

    _items.sort((a, b) => compareAsciiUpperCase(a['name']!, b['name']!));

    setState(() {
      comicList = _items;

      keyList = List.generate(_items.length, (index) => GlobalObjectKey(index));
    });
  }

  /// 递归方式删除目录
  Future<Null> deleteDirectory(FileSystemEntity dir) async {
    if (dir is Directory) {
      final List<FileSystemEntity> children = dir.listSync();
      for (final FileSystemEntity child in children) {
        await deleteDirectory(child);
      }
    }
    await dir.delete();
  }

  void deleteItem(String dirName, int index) async {
    final path = await localPath();
    final dir = Directory('$path/$dirName');
    // 删除目录
    await deleteDirectory(dir);
    // 删除 state
    comicList.removeAt(index);
    // 删除数据库已有翻译
    SqfliteManager db = await SqfliteManager.getInstance();
    db.customDelete(
      SqfliteManager.translationTable,
      'comicName = ?',
      [dirName],
    );
    // 删除数据库已读章节页数
    db.customDelete(
      SqfliteManager.comicTable,
      'comicName = ?',
      [dirName],
    );
  }

  void _showSnackBar(String action) {
    print("title: '当前点击按钮：$action'");
  }

  void delDialog(String dirName, int index) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('删除'),
        content: Text('是否删除: ${comicList[index]["name"]!}'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context, '取消');
              Slidable.of(keyList[index].currentContext!)!.close();
              alive = false;
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, '确认');
              Slidable.of(keyList[index].currentContext!)!.dismiss();
              alive = true;
              deleteItem(comicList[index]["name"]!, index);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Comic Lists',
          style: TextStyle(fontSize: 17),
        ),
        toolbarHeight: 44,
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
        key: key1,
        itemCount: comicList.length,
        itemBuilder: (context, index) {
          return Slidable(
            key: Key(comicList[index]["name"]!),
            actionPane: SlidableScrollActionPane(), // 滑出选项的面板动画
            actionExtentRatio: 0.25,
            child: ListItem(
              key: keyList[index],
              title: comicList[index]["name"]!,
              onTap: () async {
                Navigator.pushNamed(
                  context,
                  '/chapterList/${comicList[index]["name"]}',
                );
              },
            ),
            dismissal: SlidableDismissal(
              child: SlidableDrawerDismissal(),
              onWillDismiss: (actionType) {
                return alive;
              },
              onDismissed: (actionType) {
                print(actionType);
              },
            ),
            actions: <Widget>[
              // 左侧按钮列表
              IconSlideAction(
                caption: 'Archive',
                color: Colors.blue,
                icon: Icons.archive,
                onTap: () => _showSnackBar('Archive'),
              ),
              IconSlideAction(
                caption: 'Share',
                color: Colors.indigo,
                icon: Icons.share,
                onTap: () => _showSnackBar('Share'),
              ),
            ],
            secondaryActions: <Widget>[
              // 右侧按钮列表
              IconSlideAction(
                caption: 'More',
                color: Colors.black45,
                icon: Icons.more_horiz,
                onTap: () => _showSnackBar('More'),
              ),
              IconSlideAction(
                caption: 'Delete',
                color: Colors.red,
                icon: Icons.delete,
                closeOnTap: false,
                onTap: () {
                  delDialog(comicList[index]["name"]!, index);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class ListItem extends StatelessWidget {
  final String title;
  final GestureTapCallback? onTap;
  const ListItem({Key? key, required this.title, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Slidable.of(context)!.close();

        if (onTap != null) {
          onTap!();
        }
      },
      child: Container(
        color: Colors.white,
        child: ListTile(
          leading: const Icon(Icons.folder),
          title: Text(
            title,
          ),
        ),
      ),
    );
  }
}
