import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:i_comic/comic/common/global.dart';
import 'package:i_comic/comic/utils/sqflite_db.dart';
import 'package:i_comic/comic/utils/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:i_comic/comic/models/comic.dart';
import 'dart:convert';

class ImageList extends StatefulWidget {
  final String path;
  final int page;

  const ImageList({Key? key, required this.path, required this.page})
      : super(key: key);

  @override
  _ImageListState createState() => _ImageListState(path, page);
}

class _ImageListState extends State<ImageList> {
  final String path;
  final int page;

  List<String> imageData = [];
  ScrollController _scrollController = ScrollController();
  double screenWidth = window.physicalSize.width / window.devicePixelRatio;

  late Offset pointerStart;
  late Offset pointerEnd;
  double touchRangeX = 0;
  double nextOffset = 0;
  int lastPage = 0;
  late int dbPageId;

  _ImageListState(this.path, this.page);

  @override
  void initState() {
    super.initState();
    print('imageList');

    getImageInfo();
  }

  Future<String> localPath() async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<void> getImageInfo() async {
    final rootPath = await localPath();

    final dir = Directory('$rootPath/$path');
    print(dir);

    final List<String> _imageData = [];

    await for (FileSystemEntity entity
        in dir.list(recursive: true, followLinks: false)) {
      _imageData.add(entity.path);
    }

    _imageData.sort();

    /// 查看是否第一次打开
    /// 如果第一次打开，则先插入一条数据
    /// 后续翻页时对该条数据做更新
    SqfliteManager db = await SqfliteManager.getInstance();
    List<String> pathList = path.split('/');
    String comicName = pathList[0];
    String chapter = pathList[1];

    var queryRes = await db.query(
      SqfliteManager.comicTable,
      where: 'comicName = ? and chapter = ?',
      whereArgs: [comicName, chapter],
    );

    if (queryRes.length == 0) {
      dbPageId = await db.insert(
        SqfliteManager.comicTable,
        {
          'comicName': comicName,
          'chapter': chapter,
          'imgPage': 1,
        },
      );
    } else {
      // 理论上只有 1 条
      dbPageId = queryRes[0]['id'];
    }

    setState(() {
      imageData = _imageData;

      // 滚动到指定位置
      lastPage = page - 1;
      _scrollController.jumpTo(lastPage * screenWidth);
    });
  }

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
          setState(() {
            lastPage = lastPage - 1;
          });
          animateToOffset(_scrollController, lastPage * screenWidth, () {});
          savePage(lastPage);
        } else if (pointerEnd.dx > screenWidth / 3 * 2) {
          print('当前点击右侧');
          if (lastPage == imageData.length - 1) return;
          setState(() {
            lastPage = lastPage + 1;
          });
          animateToOffset(_scrollController, lastPage * screenWidth, () {});
          savePage(lastPage);
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
        setState(() {
          lastPage = lastPage - 1;
        });
        animateToOffset(_scrollController, lastPage * screenWidth, () {});
        savePage(lastPage);
        print('lastPage: $lastPage');
      } else if (touchRangeX > 0 && lastPage < imageData.length - 1) {
        // 从右到左
        print('从右到左 下一页');
        setState(() {
          lastPage = lastPage + 1;
        });
        animateToOffset(_scrollController, lastPage * screenWidth, () {});
        savePage(lastPage);
        print('lastPage: $lastPage');
      }
    };
  }

  /// 保存当前页数
  void savePage(int currentPage) async {
    SqfliteManager db = await SqfliteManager.getInstance();
    List<String> pathList = path.split('/');
    db.update(
      SqfliteManager.comicTable,
      {
        'comicName': pathList[0],
        'chapter': pathList[1],
        'imgPage': currentPage + 1,
      },
      dbPageId,
    );
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
    ComicModel comic = context.watch<ComicModel>();

    return AnnotatedRegion(
      value: SystemUiOverlayStyle.light,
      child: Material(
        child: Container(
          color: Colors.black,
          child: Stack(
            children: [
              ListView.builder(
                physics:
                    comic.isScroll ? null : new NeverScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                controller: _scrollController,
                itemCount: imageData.length,
                itemExtent: screenWidth,
                cacheExtent: screenWidth * Global.reRenderPage,
                itemBuilder: (context, index) {
                  return ImageDetail(
                    filePath: imageData[index],
                    getPointDown: getPointDownListenerInHorizontal(),
                    getPointUp: getPointUpListenerInHorizontal(),
                  );
                },
              ),
              Positioned(
                bottom: 15,
                right: 20,
                child: Text(
                  '${lastPage + 1}/${imageData.length}',
                  style: TextStyle(color: Colors.white),
                ),
              )
            ],
          ),
        ),
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
  bool showTrans = true;
  List<Words> transWords = [];
  // load
  bool loading = false;

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
  void initState() {
    setWords();
    super.initState();
  }

  void setWords() async {
    final directory = await getApplicationDocumentsDirectory();

    String fullPath = filePath.split(directory.path)[1];
    Uri uri = Uri.parse(fullPath);
    String comicName = uri.pathSegments[0];
    String chapter = uri.pathSegments[1];
    String imgName = uri.pathSegments[2];

    SqfliteManager db = await SqfliteManager.getInstance();
    List<Map<String, dynamic>> resDB = await db.query(
      SqfliteManager.translationTable,
      where: 'comicName = ? and chapter = ? and imgName = ?',
      whereArgs: [comicName, chapter, imgName],
    );

    List<Words> res;

    if (resDB.length == 0) {
      if (Global.autoTrans != 1) {
        print('没有开启自动翻译');
        return;
      }

      setState(() {
        loading = true;
      });
      List<Words> _transWords = Global.accuration == 0
          ? await getTransInfoByYD(getBase64())
          : await getTransInfo(
              getBase64(),
              Global.accuration == 2 ? 1 : 0,
            );
      setState(() {
        loading = false;
      });

      res = _transWords;

      await db.insert(SqfliteManager.translationTable, {
        'comicName': comicName,
        'chapter': chapter,
        'imgName': imgName,
        'words': json.encode(_transWords)
      });
      print('$imgName insert success!');
    } else {
      res = json
          .decode(resDB[0]['words'])
          .map<Words>(
            (json) => Words.fromJson(json),
          )
          .toList();
      print('get data in sqlite');
    }

    setState(() {
      transWords = res;
    });
  }

  /// 重新请求翻译
  /// accuration
  void resetWords(int accuration) async {
    final directory = await getApplicationDocumentsDirectory();

    String fullPath = filePath.split(directory.path)[1];
    Uri uri = Uri.parse(fullPath);
    String comicName = uri.pathSegments[0];
    String chapter = uri.pathSegments[1];
    String imgName = uri.pathSegments[2];

    SqfliteManager db = await SqfliteManager.getInstance();
    // 删除已有的
    await db.customDelete(
      SqfliteManager.translationTable,
      'comicName = ? and chapter = ? and imgName = ?',
      [comicName, chapter, imgName],
    );

    List<Words> res;

    setState(() {
      loading = true;
    });
    List<Words> _transWords = accuration == 0
        ? await getTransInfoByYD(getBase64())
        : await getTransInfo(
            getBase64(),
            accuration == 2 ? 1 : 0,
          );
    setState(() {
      loading = false;
    });

    res = _transWords;

    await db.insert(SqfliteManager.translationTable, {
      'comicName': comicName,
      'chapter': chapter,
      'imgName': imgName,
      'words': json.encode(_transWords)
    });
    print('$imgName insert success!');

    setState(() {
      transWords = res;
      showTrans = true;
    });
  }

  // 图片转 base64
  String getBase64() {
    final bytes = File(this.filePath).readAsBytesSync();
    String img64 = base64Encode(bytes);

    return img64;
  }

  /// 设置页面
  Widget settingSection(ComicModel comic) {
    return showSetting
        ? Positioned(
            left: 0,
            top: 0,
            child: GestureDetector(
              onTap: () {
                print('tap');
                setState(() {
                  comic.isScroll = true;
                  showSetting = false;
                });
              },
              child: SafeArea(
                child: Center(
                  child: Container(
                    height: screenHeight,
                    width: screenWidth,
                    color: Color.fromARGB(170, 0, 0, 0),
                    child: Column(
                      children: [
                        ...(transWords.map(
                          (e) => Container(
                            padding: EdgeInsets.all(5),
                            child: Text(
                              e.words,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ))
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        : Container();
  }

  double calcSize(double size, dynamic data, {offset = false}) {
    double scale = screenWidth / data.width;
    double _offset = (screenHeight - (data.height * scale)) / 2;
    return scale * size + (offset ? _offset : 0);
  }

  /// 翻译页面
  Widget transSection(ComicModel comic) {
    File image = File(filePath);

    return showTrans
        ? FutureBuilder(
            future: decodeImageFromList(image.readAsBytesSync()),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasError) print(snapshot.error);
              if (snapshot.hasData) {
                print(
                    'size: ${snapshot.data!.width},  ${snapshot.data!.height}');
                print('screenWidth: $screenWidth');
                print('screenHeight: $screenHeight');
              }

              return snapshot.hasData
                  ? Stack(
                      children: [
                        ...(transWords.map(
                          (e) => Positioned(
                            left: calcSize(e.location.left, snapshot.data),
                            top: calcSize(e.location.top, snapshot.data,
                                offset: true),
                            child: Container(
                              // height:
                              //     calcSize(e.location.height, snapshot.data),
                              width: calcSize(e.location.width, snapshot.data),
                              color: Colors.red,
                              padding: EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                e.words,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.black,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ))
                      ],
                    )
                  : Center(child: CircularProgressIndicator());
            },
          )
        : Container();
  }

  /// 重新翻译弹窗
  void _showDialog(int accuration) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('重新获取翻译'),
        content: Text('是否重新获取${transMap[accuration]}翻译？'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context, '取消');
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, '确认');
              resetWords(accuration);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ComicModel comic = context.watch<ComicModel>();

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
            if (dx > centerX[0] && dx < centerX[1] && dy > centerY[1]) {
              print('点击了中下位置: ${e.localPosition.dx}, ${e.localPosition.dy}');
              setState(() {
                comic.isScroll = false;
                showSetting = true;
              });
            } else if (dx > centerX[0] &&
                dx < centerX[1] &&
                dy > centerY[0] &&
                dy < centerY[1]) {
              print('点击了中心位置: ${e.localPosition.dx}, ${e.localPosition.dy}');
              setState(() {
                showTrans = !showTrans;
              });
            } else if (dx > (screenWidth / 2) &&
                dx <= centerX[1] &&
                dy < centerY[0]) {
              print('点击了中上偏右位置: ${e.localPosition.dx}, ${e.localPosition.dy}');
              setState(() {
                _showDialog(Global.accuration == 0 ? 1 : 0);
              });
            } else if (dx >= centerX[0] &&
                dx < (screenWidth / 2) &&
                dy < centerY[0]) {
              print('点击了中上偏左位置: ${e.localPosition.dx}, ${e.localPosition.dy}');
              setState(() {
                _showDialog(Global.accuration);
              });
            }

            getPointUp(e);
          },
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Center(
                child: Container(
                  height: screenHeight,
                  child: Image.file(
                    File(filePath),
                  ),
                ),
              ),
              transSection(comic),
              loading
                  ? Positioned(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Container(),
            ],
          ),
        ),
        settingSection(comic),
        // 蒙层
      ],
    );
  }
}
