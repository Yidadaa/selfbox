import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../gen/assets/assets.gen.dart';
import '../theme/app_artwork_tokens.dart';

enum BrandArt {
  logo,
  avatar,
  welcome,
  messages,
  search,
  files,
  recorded,
  thinking,
  error,
  offline,
  empty,
  success,
  sleep,
  working,
  playing,
  sleeping,
  resting,
  reading,
  awake;

  AssetGenImage get asset => switch (this) {
    logo => Assets.brand.logo,
    avatar => Assets.brand.avatarDefault,
    welcome => Assets.brand.emptyWelcome,
    messages => Assets.brand.emptyMessages,
    search => Assets.brand.emptySearch,
    files => Assets.brand.emptyFiles,
    recorded => Assets.brand.feedbackRecorded,
    thinking => Assets.brand.feedbackThinking,
    error => Assets.brand.feedbackError,
    offline => Assets.brand.feedbackOffline,
    empty => Assets.brand.smallEmpty,
    success => Assets.brand.smallSuccess,
    sleep => Assets.brand.smallSleep,
    working => Assets.brand.stateWorking,
    playing => Assets.brand.statePlaying,
    sleeping => Assets.brand.stateSleeping,
    resting => Assets.brand.stateResting,
    reading => Assets.brand.stateReading,
    awake => Assets.brand.stateAwake,
  };
}

/// Decorative artwork uses the same intrinsic layout before and after decoding.
class AppArtwork extends StatelessWidget {
  const AppArtwork(
    this.artwork, {
    this.size = AppArtworkTokens.hero,
    super.key,
  });

  final BrandArt artwork;
  final double size;

  @override
  Widget build(BuildContext context) => artwork.asset.image(
    width: size,
    height: size,
    fit: BoxFit.contain,
    excludeFromSemantics: true,
    cacheWidth: math.min(
      (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
      AppArtworkTokens.maxDecodeSize,
    ),
  );
}
