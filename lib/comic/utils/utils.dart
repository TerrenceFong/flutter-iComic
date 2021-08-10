import 'dart:math' as math;
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:i_comic/comic/common/global.dart';

class Words {
  String words;
  Location location;

  Words({required this.words, required this.location});

  factory Words.fromJson(Map<String, dynamic> json) {
    return Words(
      words: json['words'] as String,
      location: Location.fromJson(json['location']),
    );
  }

  Map toJson() {
    return {
      'words': words,
      'location': location.toMap(),
    };
  }

  Map toMap() {
    return {
      'words': words,
      'location': location.toMap(),
    };
  }
}

class Location {
  final double top;
  final double left;
  final double width;
  final double height;

  Location({
    required this.top,
    required this.left,
    required this.width,
    required this.height,
  });

  factory Location.fromJson(dynamic json) {
    return Location(
      top: json['top'].toDouble(),
      left: json['left'].toDouble(),
      width: json['width'].toDouble(),
      height: json['height'].toDouble(),
    );
  }

  Map<String, double> toMap() {
    return {
      'top': top,
      'left': left,
      'width': width,
      'height': height,
    };
  }
}

/// 查看 op 是否在 target 的 ±range 范围内
bool nearInt(op, target, range) {
  return op < target + range && op > target - range;
}

/// 整理识别出来的文字
///
/// 将相邻的部分合并在一起
List<Words> arrangeWords(List<Words> words) {
  List<Words> filterWords = [];

  if (words.length > 1) {
    String word = '';
    Map<String, double> position = {
      'top': 0,
      'left': 0,
      'width': 0,
      'height': 0
    };
    Map<String, double> targetPosition = {
      'top': 0,
      'left': 0,
      'width': 0,
      'height': 0
    };

    for (int i = 0; i < words.length; i++) {
      final e = words[i];
      // 第一项先入库
      if (i == 0) {
        word += e.words;
        position = e.location.toMap();
        targetPosition = e.location.toMap();
      } else {
        // 后续的跟前一项比较
        if (nearInt(position['top'], e.location.top, Global.nearTop) &&
            nearInt(position['left']! + position['width']!, e.location.left,
                Global.nearLeft)) {
          word = e.words + word;
          position = e.location.toMap();
          targetPosition['width'] = targetPosition['width']! + e.location.width;
          targetPosition['height'] =
              math.max<double>(targetPosition['height']!, e.location.height);
        } else {
          // 遇到不相邻的，先把之前匹配的推入队列
          filterWords.add(
              Words(words: word, location: Location.fromJson(targetPosition)));
          // 重新初始化
          word = '';
          position = {'top': 0, 'left': 0, 'width': 0, 'height': 0};
          targetPosition = {'top': 0, 'left': 0, 'width': 0, 'height': 0};

          word += e.words;
          position = e.location.toMap();
          targetPosition = e.location.toMap();
        }

        // 最后一项的处理
        if (i == words.length - 1) {
          filterWords.add(
              Words(words: word, location: Location.fromJson(targetPosition)));
        }
      }
    }
  } else if (words.length == 1) {
    filterWords.add(words[0]);
  }

  return filterWords;
}

class MD5Util {
  static String generateMd5(String data) {
    Uint8List content = new Utf8Encoder().convert(data);
    Digest digest = md5.convert(content);
    // 这里其实就是 digest.toString()
    return hex.encode(digest.bytes);
  }
}

Future<List<String>> bdTrans(String query, {bool? isMulti}) async {
  String decodeQuery = Uri.encodeComponent(query);
  String appid = '20210729000900971';
  String key = 'ZGdTJRGaQi9FxI4lMZgM';
  String salt = DateTime.now().millisecondsSinceEpoch.toString();
  String str1 = appid + query + salt + key;
  String sign = MD5Util.generateMd5(str1);

  String from = 'jp';
  String to = 'zh';

  final res = await http.Client().get(
    Uri.parse(
      'https://fanyi-api.baidu.com/api/trans/vip/translate?q=$decodeQuery&appid=$appid&salt=$salt&from=$from&to=$to&sign=$sign',
    ),
  );

  if (res.statusCode == 200) {
    Utf8Decoder utf8decoder = Utf8Decoder();
    final parsed = json.decode(utf8decoder.convert(res.bodyBytes));

    List<String> transResult =
        (parsed['trans_result'] as List).map<String>((e) => e['dst']).toList();
    print('bdt: $transResult');

    return transResult;
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to get baidu translate.');
  }
}

/// 翻译 List
Future<List<Words>> translateWords(List<Words> words) async {
  List<Words> transWords = [];

  if (words.length == 0) {
    return transWords;
  }

  List<String> wordsList = [];

  // 收集所有文案 一次性翻译，避免多次查询
  for (Words e in words) {
    wordsList.add(e.words);
  }

  List<String> transList = await bdTrans(wordsList.join('\n'), isMulti: true);

  for (int i = 0; i < words.length; i++) {
    transWords.add(
      Words(
        words: transList[i],
        location: words[i].location,
      ),
    );
  }

  return transWords;
}

// 设置百度的 APPID/AK/SK
const APP_ID = '24453940';
const API_KEY = 'jTbvSE6G91krPA2xAsotWMmo';
const SECRET_KEY = 'AkD8qhftzMHPHR92vHPRDcs9hy8D2yrn';

/// 百度 api 的 access-token
Future<void> getBdAccessToken() async {
  final res = await http.Client().get(
    Uri.parse(
      'https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id=$API_KEY&client_secret=$SECRET_KEY',
    ),
  );

  if (res.statusCode == 200) {
    Utf8Decoder utf8decoder = Utf8Decoder();
    final parsed =
        json.decode(utf8decoder.convert(res.bodyBytes))['access_token'];

    Global.bdAccessToken = parsed;
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to get access token.');
  }
}

/// 百度 api 提取文字并翻译
Future<List<Words>> getTransInfo(String image, int type) async {
  List<String> pathMap = ['accurate', 'general'];

  // final res = await http.Client().post(
  //   Uri.parse(
  //       'https://42d3g2teii.execute-api.us-east-1.amazonaws.com/prod/api/sp-lottery/trans-info'),
  //   headers: <String, String>{
  //     'Content-Type': 'application/json; charset=UTF-8',
  //   },
  //   body: jsonEncode(<String, dynamic>{
  //     'image': image,
  //     'type': type,
  //   }),
  // );
  final Uri uri = Uri.parse(
    'https://aip.baidubce.com/rest/2.0/ocr/v1/${pathMap[type]}?access_token=${Global.bdAccessToken}',
  );
  final res = await http.post(
    uri,
    body: {
      'image': image,
      'language_type': 'JAP',
    },
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    encoding: Encoding.getByName('utf-8'),
  );

  if (res.statusCode == 200) {
    Utf8Decoder utf8decoder = Utf8Decoder();
    final parsed =
        json.decode(utf8decoder.convert(res.bodyBytes))['words_result'];

    final wordsData =
        parsed.map<Words>((json) => Words.fromJson(json)).toList();

    List<Words> transWords = await translateWords(arrangeWords(wordsData));

    return transWords;
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to get translate.');
  }
}

/// 有道云 api 提取文字并翻译
Future<List<Words>> getTransInfoByYD(String img64) async {
  String appId = "6594b3be1a800663";
  String appKey = "B62yN7nQA6C3MDoijgagWTWMZKuswifp";
  String currentTime =
      (DateTime.now().millisecondsSinceEpoch / 1000).truncate().toString();
  String salt = (int.parse(currentTime) * math.Random().nextInt(1)).toString();
  String input =
      '${img64.substring(0, 10)}${img64.length}${img64.substring(img64.length - 10)}';
  String str1 = appId + input + salt + currentTime + appKey;
  String sign = sha256.convert(utf8.encode(str1)).toString();

  final Uri uri = Uri.parse('https://openapi.youdao.com/ocrapi');
  final res = await http.post(
    uri,
    body: {
      "img": img64,
      "langType": "ja",
      "detectType": "10012",
      "imageType": "1",
      "appKey": appId,
      "salt": salt,
      "sign": sign,
      "docType": 'json',
      "signType": 'v3',
      "curtime": currentTime,
      "column": "columns",
    },
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    encoding: Encoding.getByName('utf-8'),
  );

  if (res.statusCode == 200) {
    Utf8Decoder utf8decoder = Utf8Decoder();
    final parsed =
        json.decode(utf8decoder.convert(res.bodyBytes))['Result']['regions'];

    List<Words> wordsData = [];

    for (var i = 0; i < parsed.length; i++) {
      var outer = parsed[i];
      for (int i = 0; i < outer['lines'].length; i++) {
        var e = outer['lines'][i];

        wordsData.add(Words.fromJson(
            {'words': e['text'], 'location': calcLocation(e['boundingBox'])}));
      }
    }

    List<Words> transWords =
        await translateWords(arrangeWords(wordsData.reversed.toList()));

    return transWords;
  } else {
    throw Exception('Failed to get baidu translate.');
  }
}

/// 将 x1,y1,x2,y2,x3,y3,x4,y4 转化为 location 对象
Map<String, dynamic> calcLocation(String location) {
  var arr = location.split(',').map<int>((e) => int.parse(e)).toList();

  int top = arr[1];
  int left = arr[0];
  int width = arr[2] - arr[0];
  int height = arr[5] - arr[3];

  return {
    'top': top,
    'left': left,
    'width': width,
    'height': height,
  };
}

/// 百度相关信息
String bdAppId = '20210729000900971';
String bdSercet = 'ZGdTJRGaQi9FxI4lMZgM';
