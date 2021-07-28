import 'dart:math' as math;
import 'package:translator/translator.dart';

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
  final int top;
  final int left;
  final int width;
  final int height;

  Location({
    required this.top,
    required this.left,
    required this.width,
    required this.height,
  });

  factory Location.fromJson(dynamic json) {
    return Location(
      top: json['top'] as int,
      left: json['left'] as int,
      width: json['width'] as int,
      height: json['height'] as int,
    );
  }

  Map<String, int> toMap() {
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
    Map<String, int> position = {'top': 0, 'left': 0, 'width': 0, 'height': 0};
    Map<String, int> targetPosition = {
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
              math.max<int>(targetPosition['height']!, e.location.height);
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
Future<List<Words>> translateWords(List<Words> words) async {
  final translator = GoogleTranslator();

  List<Words> transWords = [];

  for (Words e in words) {
    var transWord =
        (await translator.translate(e.words, from: 'ja', to: 'zh-cn'))
            .toString();

    transWords.add(
      Words(
        words: transWord,
        location: e.location,
      ),
    );
  }

  return transWords;
}
