import 'package:flutter/widgets.dart';

abstract final class AppAiTokens {
  static List<Color> contentColors(Brightness brightness) =>
      switch (brightness) {
        Brightness.light => const [
          Color(0xFFAF486A),
          Color(0xFF8151B0),
          Color(0xFF3E6EB5),
          Color(0xFF287B80),
        ],
        Brightness.dark => const [
          Color(0xFFF0A7BA),
          Color(0xFFC5A6EA),
          Color(0xFFA4BFF3),
          Color(0xFF99D5D4),
        ],
      };
}
