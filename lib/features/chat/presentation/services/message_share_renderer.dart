import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/theme/message_share_tokens.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/message.dart';
import '../widgets/message_share_card.dart';

part '../../../../gen/features/chat/presentation/services/message_share_renderer.g.dart';

const messageShareTooLong = 'message share exceeds raster budget';

typedef MessageShareRenderer = TaskEither<AppFailure, Uint8List> Function(
  BuildContext context,
  Message message,
);

@riverpod
MessageShareRenderer messageShareRenderer(Ref ref) => renderMessageShare;

TaskEither<AppFailure, Uint8List> renderMessageShare(
  BuildContext context,
  Message message,
) => TaskEither.tryCatch(() async {
  final view = View.of(context);
  final content = InheritedTheme.captureAll(
    context,
    UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          size: const Size(MessageShareTokens.width, 1),
          devicePixelRatio: MessageShareTokens.pixelRatio,
          textScaler: TextScaler.noScaling,
          disableAnimations: true,
        ),
        child: Directionality(
          textDirection: Directionality.of(context),
          child: InheritedLocaleData<AppLocale, Translations>(
            translations: context.t,
            child: MessageShareCard(message: message),
          ),
        ),
      ),
    ),
  );
  return _render(view, content);
}, AppFailure.fromError).flatMap(TaskEither.fromEither);

Future<Either<AppFailure, Uint8List>> _render(
  ui.FlutterView view,
  Widget content,
) async {
  final boundary = RenderRepaintBoundary();
  final overflow = RenderConstrainedOverflowBox(
    alignment: Alignment.topLeft,
    minWidth: MessageShareTokens.width,
    maxWidth: MessageShareTokens.width,
    minHeight: 0,
    maxHeight: double.infinity,
    child: boundary,
  );
  final renderView = RenderView(
    view: view,
    configuration: const ViewConfiguration(
      logicalConstraints: BoxConstraints.tightFor(
        width: MessageShareTokens.width,
        height: 1,
      ),
      physicalConstraints: BoxConstraints.tightFor(
        width: MessageShareTokens.width,
        height: 1,
      ),
    ),
    child: overflow,
  );
  final pipeline = PipelineOwner()..rootNode = renderView;
  final owner = BuildOwner(focusManager: FocusManager());
  renderView.prepareInitialFrame();
  final root = RenderObjectToWidgetAdapter<RenderBox>(
    container: boundary,
    child: content,
  ).attachToRenderTree(owner);
  void draw() {
    owner.buildScope(root);
    pipeline
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();
  }

  try {
    draw();
    // Decode the actual Image providers, including AppArtwork's resize keys.
    final images = <Future<void>>[];
    void collect(Element element) {
      final widget = element.widget;
      if (widget is Image) images.add(precacheImage(widget.image, element));
      element.visitChildren(collect);
    }

    root.visitChildren(collect);
    await Future.wait(images).timeout(const Duration(seconds: 15));
    draw();
    final ratio = MessageShareTokens.rasterRatio(boundary.size);
    if (!ratio.isFinite || ratio < 1) {
      return const Left(AppFailure.validation(message: messageShareTooLong));
    }
    final image = await boundary.toImage(pixelRatio: ratio);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes == null
          ? const Left(AppFailure.validation(message: 'PNG encoding failed'))
          : Right(
              bytes.buffer.asUint8List(
                bytes.offsetInBytes,
                bytes.lengthInBytes,
              ),
            );
    } finally {
      image.dispose();
    }
  } finally {
    RenderObjectToWidgetAdapter<RenderBox>(container: boundary)
        .attachToRenderTree(owner, root);
    owner.buildScope(root);
    owner.finalizeTree();
    pipeline.rootNode = null;
    renderView.child = null;
    overflow.child = null;
    boundary.dispose();
    overflow.dispose();
    renderView.dispose();
    pipeline.dispose();
    owner.focusManager.dispose();
  }
}
