import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:my_app/comic/models/comic.dart';

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
  double screenWidth = window.physicalSize.width / window.devicePixelRatio;
  // bool isScroll = true;

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

    _imageData.sort();

    setState(() {
      imageData = _imageData;

      // 滚动到指定位置
      // 该值从本地获取
      // _scrollController.jumpTo(3 * screenWidth);
      // lastPage = 3;
    });
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
        .animateTo(
      offset,
      duration: Duration(milliseconds: 200),
      curve: Curves.easeIn,
    )
        .then((value) {
      onScrollCompleted();
    }).catchError((e) {
      print(e);
    });
  }

  @override
  Widget build(BuildContext context) {
    print('imageList build');
    var comic = context.watch<ComicModel>();

    return Container(
      color: Colors.black,
      child: ListView.builder(
        physics: comic.isScroll ? null : new NeverScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        itemCount: imageData.length,
        itemExtent: screenWidth,
        itemBuilder: (context, index) {
          return ImageDetail(
            filePath: imageData[index],
            getPointDown: getPointDownListenerInHorizontal(),
            getPointUp: getPointUpListenerInHorizontal(),
          );
        },
      ),
    );
  }
}

class ImageDetail extends StatefulWidget {
  final String filePath;
  final PointerDownEventListener getPointDown;
  final PointerUpEventListener getPointUp;

  const ImageDetail({
    Key? key,
    required this.filePath,
    required this.getPointDown,
    required this.getPointUp,
  }) : super(key: key);

  @override
  _ImageDetailState createState() =>
      _ImageDetailState(filePath, getPointDown, getPointUp);
}

class _ImageDetailState extends State<ImageDetail> {
  final String filePath;
  final PointerDownEventListener getPointDown;
  final PointerUpEventListener getPointUp;
  double dpr = window.devicePixelRatio;
  double screenWidth = window.physicalSize.width / window.devicePixelRatio;
  double screenHeight = window.physicalSize.height / window.devicePixelRatio;
  bool showSetting = false;

  _ImageDetailState(this.filePath, this.getPointDown, this.getPointUp);

  List<double> get centerX {
    double perPartSize = screenWidth / 3;
    return [perPartSize, perPartSize * 2];
  }

  List<double> get centerY {
    double halfHeight = screenHeight / 2;
    return [halfHeight - halfHeight / 3, halfHeight + halfHeight / 3];
  }

  @override
  Widget build(BuildContext context) {
    var comic = context.watch<ComicModel>();

    return Stack(
      children: <Widget>[
        // 图片
        Listener(
          onPointerDown: (PointerDownEvent e) {
            getPointDown(e);
          },
          onPointerUp: (PointerUpEvent e) {
            double dx = e.localPosition.dx;
            double dy = e.localPosition.dy;

            print('dx: $dx, dy: $dy');

            // 左右侧在父级处理
            // 中间区域检测
            if (dx > centerX[0] &&
                dx < centerX[1] &&
                dy > centerY[0] &&
                dy < centerY[1]) {
              print('点击了中心位置: ${e.localPosition.dx}, ${e.localPosition.dy}');
              setState(() {
                comic.isScroll = false;
                showSetting = true;
              });
            }

            getPointUp(e);
          },
          child: Center(
            child: Container(
              height: screenHeight,
              child: Image.file(
                File(filePath),
              ),
            ),
          ),
        ),
        // 蒙层
        Positioned(
          left: 0,
          top: 0,
          child: showSetting
              ? GestureDetector(
                  onTap: () {
                    print('tap');
                    setState(() {
                      comic.isScroll = true;
                      showSetting = false;
                    });
                  },
                  child: Container(
                    height: screenHeight,
                    width: screenWidth,
                    color: Color.fromARGB(80, 0, 0, 0),
                    child: Text('ffff'),
                  ),
                )
              : Container(),
        )
      ],
    );
  }
}
