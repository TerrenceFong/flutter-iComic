import 'dart:math' as math;
import 'package:translator/translator.dart';
import 'package:http/http.dart' as http;

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

    for (var i = 0; i < words.length; i++) {
      final e = words[i];
      // 第一项先入库
      if (i == 0) {
        word += e.words;
        position = e.location.toMap();
        targetPosition = e.location.toMap();
      } else {
        // 后续的跟前一项比较
        if (nearInt(position['top'], e.location.top, 5) &&
            nearInt(
                position['left']! + position['width']!, e.location.left, 7)) {
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

/// 翻译 List
Future<List<Words>> translateWords(List<Words> words, bool useBd) async {
  final translator = GoogleTranslator();

  List<Words> transWords = [];

  for (Words e in words) {
    String transWord = '';
    try {
      transWord = useBd
          ? (await translator.translate(e.words, from: 'ja', to: 'zh-cn'))
              .toString()
          : e.words;
    } catch (e) {
      print('translate word error: $e');
    }

    transWords.add(
      Words(
        words: transWord,
        location: e.location,
      ),
    );
  }

  return transWords;
}

/// 百度相关信息
String bdAppId = '20210729000900971';
String bdSercet = 'ZGdTJRGaQi9FxI4lMZgM';
