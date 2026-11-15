import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:selfbox/core/theme/app_icons.dart';

void main() {
  test('AI and settings actions use their assigned Hugeicons glyphs', () {
    expect(AppIcons.ai, HugeIcons.strokeRoundedAiSparkles);
    expect(AppIcons.chat, HugeIcons.strokeRoundedMessage02);
    expect(AppIcons.memory, HugeIcons.strokeRoundedCards02);
    expect(AppIcons.profile, HugeIcons.strokeRoundedBlackHole01);
    expect(AppIcons.quote, HugeIcons.strokeRoundedQuotes);
    expect(AppIcons.search, HugeIcons.strokeRoundedSearch01);
    expect(AppIcons.aiHidden, HugeIcons.strokeRoundedMagicWand02);
    expect(AppIcons.aiMode, HugeIcons.strokeRoundedPawPrint);
    expect(AppIcons.aiConfig, HugeIcons.strokeRoundedAlien01);
    expect(AppIcons.modelSelection, HugeIcons.strokeRoundedAlien02);
    expect(AppIcons.provider, HugeIcons.strokeRoundedSpaceship);
    expect(AppIcons.about, HugeIcons.strokeRoundedLookLeft);
    expect(AppIcons.selectText, HugeIcons.strokeRoundedInputCursorText);
    expect(AppIcons.download, HugeIcons.strokeRoundedDownload02);
  });
}
