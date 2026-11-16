import 'package:flutter/material.dart';
import 'package:selfbox/core/widgets/measure_size.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer_tabs.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_preview.dart';

Map<String, Object?> inspectScene() {
  final previews = <double>[];
  var inset = 0.0;
  var tabsHeight = 0.0;
  var keyboardOpen = false;
  void measurePreview(Element element) {
    if (element.widget is MeasureSize) {
      final render = element.findRenderObject();
      if (render is RenderBox && render.hasSize) {
        previews.add(render.size.height);
      }
      return;
    }
    element.visitChildren(measurePreview);
  }

  void visit(Element element) {
    if (element.widget is EditableText) {
      inset = MediaQuery.viewInsetsOf(element).bottom;
    }
    if (element.widget case final ChatComposerTabs tabs) {
      keyboardOpen = tabs.keyboardOpen;
      final render = element.findRenderObject();
      if (render is RenderBox && render.hasSize) {
        tabsHeight = render.size.height;
      }
    }
    if (element.widget is MessagePreview) measurePreview(element);
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement!.visitChildren(visit);
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  return {
    'insetDp': inset,
    'viewInsetDp': view.viewInsets.bottom / view.devicePixelRatio,
    'tabsHeightDp': tabsHeight,
    'keyboardOpen': keyboardOpen,
    'screenHeightDp': view.physicalSize.height / view.devicePixelRatio,
    'mountedContentHeightsDp': previews,
  };
}
