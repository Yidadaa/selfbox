import 'package:flutter/painting.dart';

/// 8pt/4pt spatial grid. Every gap and padding in the app must come from here.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;

  static const List<double> scale = [xxs, xs, sm, md, lg, xl, xxl, xxxl, huge];
}

/// Component dimensions (not spacing).
abstract final class AppSizes {
  /// Minimum physical hit area for anything tappable or draggable.
  static const double minTouchTarget = 48;

  /// GlassAppBar toolbar height. GlassScaffold extends the body behind its
  /// bars, so scrollable bodies must inset by safe area + this value.
  static const double appBarHeight = 44;
  static const double chatHeaderHeight = 80;
  static const double iconMd = 24;
  static const double iconHero = 48;
  static const double sendIcon = 36;
  static const double attachmentThumbnail = 64;
  static const double profileAvatar = 80;
  static const double profileActionWidth = 160;
}

abstract final class AppInsets {
  /// Shared horizontal edge for page chrome, page content and the chat dock.
  static const double pageHorizontal = AppSpacing.md;

  /// Grouped sections sit flush with the page padding; only the space
  /// between consecutive sections is theirs.
  static const section = EdgeInsets.symmetric(vertical: AppSpacing.xxs);
}
