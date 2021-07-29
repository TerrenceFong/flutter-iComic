import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:my_app/comic/utils/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:my_app/comic/models/comic.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

    return Material(
      child: Container(
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
      ),
    );
  }
}

Future<List<Words>> getTransInfo(String image) async {
  final res = await http.Client().post(
    Uri.parse(
        'https://42d3g2teii.execute-api.us-east-1.amazonaws.com/prod/api/sp-lottery/trans-info'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'image': image,
    }),
  );

  // final jsonStr =
  //     '{"code":200,"data":{"words_result":[{"words":"甘い生活63","location":{"top":65,"left":63,"width":143,"height":31}},{"words":"イテア","location":{"top":112,"left":341,"width":30,"height":79}},{"words":"な","location":{"top":115,"left":364,"width":31,"height":73}},{"words":"あなた","location":{"top":113,"left":398,"width":22,"height":77}},{"words":"あによ?","location":{"top":116,"left":454,"width":20,"height":81}},{"words":"行動したっけ?","location":{"top":424,"left":434,"width":24,"height":131}},{"words":"今まであんな","location":{"top":425,"left":457,"width":22,"height":130}},{"words":"そう","location":{"top":606,"left":220,"width":71,"height":18}},{"words":"るれン","location":{"top":623,"left":223,"width":63,"height":21}},{"words":":","location":{"top":637,"left":222,"width":53,"height":31}},{"words":"ました?","location":{"top":746,"left":72,"width":22,"height":95}},{"words":"ちゃい","location":{"top":748,"left":92,"width":27,"height":77}},{"words":"る","location":{"top":761,"left":105,"width":27,"height":48}},{"words":"うれしそう!?","location":{"top":739,"left":834,"width":21,"height":121}},{"words":"で","location":{"top":1053,"left":90,"width":28,"height":39}},{"words":"13","location":{"top":1321,"left":65,"width":29,"height":21}}],"log_id":1419958073583525000,"words_result_num":16,"direction":0}}';
  // final res = {'statusCode': 200};

  if (res.statusCode == 200) {
    Utf8Decoder utf8decoder = Utf8Decoder();
    final parsed =
        json.decode(utf8decoder.convert(res.bodyBytes))['data']['words_result'];
    // if (res['statusCode'] == 200) {
    // final parsed = jsonDecode(jsonStr)['data']['words_result'];

    final wordsData =
        parsed.map<Words>((json) => Words.fromJson(json)).toList();

    var transWords = await translateWords(arrangeWords(wordsData), false);

    return transWords;
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to get translate.');
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
    var _transWords = await getTransInfo(getBase64());

    setState(() {
      transWords = _transWords;
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
              child: Container(
                height: screenHeight,
                width: screenWidth,
                color: Color.fromARGB(80, 0, 0, 0),
                child: Text('ffff'),
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
    // var decodedImage = await decodeImageFromList(image.readAsBytesSync())
    var image = File(filePath);

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
                              height:
                                  calcSize(e.location.height, snapshot.data),
                              width: calcSize(e.location.width, snapshot.data),
                              color: Colors.red,
                              child: Text(
                                e.words,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.black,
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
          child: Stack(
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
            ],
          ),
        ),
        settingSection(comic),
        // 蒙层
      ],
    );
  }
}
