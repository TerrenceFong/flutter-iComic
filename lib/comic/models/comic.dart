import 'package:flutter/material.dart';

class ComicModel extends ChangeNotifier {
  bool _isScroll = true;

  bool get isScroll => _isScroll;

  set isScroll(bool val) {
    _isScroll = val;
    notifyListeners();
  }
}
