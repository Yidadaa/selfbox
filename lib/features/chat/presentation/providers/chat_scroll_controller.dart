import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../../../gen/features/chat/presentation/providers/chat_scroll_controller.g.dart';

@riverpod
ScrollController chatScrollController(Ref ref) {
  final controller = ScrollController();
  ref.onDispose(controller.dispose);
  return controller;
}
