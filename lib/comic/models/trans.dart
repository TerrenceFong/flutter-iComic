import 'package:my_app/comic/utils/utils.dart';

class Trans {
  final int id;
  final String comicName;
  final String path;
  final List<Words> words;

  Trans({
    required this.id,
    required this.comicName,
    required this.path,
    required this.words,
  });
}
