import 'dart:math' as math;
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:my_app/comic/common/global.dart';

const CONFIG_ID = 1;

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

/// 百度相关信息
String bdAppId = '20210729000900971';
String bdSercet = 'ZGdTJRGaQi9FxI4lMZgM';
