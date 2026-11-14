import 'package:flutter/cupertino.dart';

abstract final class AppInputTokens {
  static Color placeholderColor(Brightness brightness) => switch (brightness) {
    Brightness.light => CupertinoColors.placeholderText.color,
    Brightness.dark => CupertinoColors.placeholderText.darkColor,
  };
}
