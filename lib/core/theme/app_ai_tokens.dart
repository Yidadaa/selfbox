import 'package:flutter/widgets.dart';

abstract final class AppAiTokens {
  static LinearGradient contentGradient(Brightness brightness) =>
      LinearGradient(colors: contentColors(brightness));

  static List<Color> contentColors(Brightness brightness) =>
      switch (brightness) {
        Brightness.light => const [
          Color(0xFFCF2450),
          Color(0xFFA62DCC),
          Color(0xFF3156DD),
        ],
        Brightness.dark => const [
          Color(0xFFFF5278),
          Color(0xFFDB5DF7),
          Color(0xFF6493FF),
        ],
      };
}
