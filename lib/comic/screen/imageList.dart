import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageList extends StatefulWidget {
  final String path;

  const ImageList({Key? key, required this.path}) : super(key: key);

  @override
  _ImageListState createState() => _ImageListState(path);
}

class _ImageListState extends State<ImageList> {
  final String path;
  List<String> imageData = [];
  String contentText = "正在加载数据";
  ScrollController _scrollController = ScrollController();
  double screenWidth = 375;

  _ImageListState(this.path);

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
    final rootPath = await localPath();

    final dir = Directory('$rootPath/$path');
    print(dir);

    final List<String> _imageData = [];

    await for (var entity in dir.list(recursive: true, followLinks: false)) {
      _imageData.add(entity.path);
    }

    setState(() {
      imageData = _imageData;
    });
    // return File('$path/test.png');
  }

  late Offset pointerStart;
  late Offset pointerEnd;
  double touchRangeX = 0;
  double nextOffset = 0;
  int lastPage = 0;

  PointerDownEventListener getPointDownListenerInHorizontal() {
    return (event) {
      pointerStart = event.position;
      print('pointerStart');
      print(pointerStart);
    };
  }

  PointerUpEventListener getPointUpListenerInHorizontal() {
    return (event) {
      pointerEnd = event.position;
      print('pointerEnd');
      print(pointerEnd);
      double offsetLimit = screenWidth / 7;

      // 触摸的水平偏移量
      touchRangeX = pointerStart.dx - pointerEnd.dx;

      print('touchRangeX: $touchRangeX');
      print(
          'touchRangeX.abs(): ${touchRangeX.abs()}, offsetLimit: $offsetLimit');
      print('now lastPage: $lastPage');
      print('');

      // 点击条件
      if (pointerStart.dx == pointerEnd.dx &&
          pointerStart.dy == pointerEnd.dy) {
        print('当前为点击操作');
        // 将屏幕分为 3 份
        if (pointerEnd.dx < screenWidth / 3) {
          print('当前点击左侧');
          if (lastPage == 0) return;
          lastPage = lastPage - 1;
          animateToOffset(_scrollController, lastPage * screenWidth, () {});
        } else if (pointerEnd.dx > screenWidth / 3 * 2) {
          print('当前点击右侧');
          if (lastPage == imageData.length - 1) return;
          lastPage = lastPage + 1;
          animateToOffset(_scrollController, lastPage * screenWidth, () {});
        }

        return;
      }

      // 滑动条件
      if (touchRangeX.abs() < offsetLimit) {
        print('自动归位');
        nextOffset = screenWidth * lastPage;
        // 小于屏幕的 1/5，自动归位
        animateToOffset(_scrollController, nextOffset, () {});
        return;
      }

      if (touchRangeX < 0 && lastPage > 0) {
        // 从左到右
        print('从左到右 上一页');
        lastPage = lastPage - 1;
        animateToOffset(_scrollController, lastPage * screenWidth, () {});
        print('lastPage: $lastPage');
      } else if (touchRangeX > 0 && lastPage < imageData.length - 1) {
        // 从右到左
        print('从右到左 下一页');
        lastPage = lastPage + 1;
        animateToOffset(_scrollController, lastPage * screenWidth, () {});
        print('lastPage: $lastPage');
      }
    };
  }

  void animateToOffset(ScrollController controller, double offset,
      void Function() onScrollCompleted) {
    controller
        .animateTo(offset,
            duration: Duration(milliseconds: 200), curve: Curves.easeIn)
        .then((value) {
      onScrollCompleted();
    }).catchError((e) {
      print(e);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          color: Colors.black,
          child: Listener(
            onPointerDown: getPointDownListenerInHorizontal(),
            onPointerUp: getPointUpListenerInHorizontal(),
            child: ListView.builder(
              // physics: new NeverScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              controller: _scrollController,
              itemCount: imageData.length,
              itemExtent: screenWidth,
              itemBuilder: (context, index) {
                return ImageDetail(filePath: imageData[index]);
              },
            ),
          ),
        )
      ],
    );
  }
}

class ImageDetail extends StatelessWidget {
  final String filePath;

  const ImageDetail({Key? key, required this.filePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // print(filePath);

    return Center(
      child: Image.file(File(filePath)),
    );
  }
}
