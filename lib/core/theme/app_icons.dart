import 'package:hugeicons/hugeicons.dart';

typedef AppIconData = List<List<Object?>>;

abstract final class AppIconTokens {
  static const double strokeWidth = 1.75;
}

/// One stroke-rounded family, named by the action each glyph represents.
abstract final class AppIcons {
  static const AppIconData back = HugeIcons.strokeRoundedArrowLeft01;
  static const AppIconData next = HugeIcons.strokeRoundedArrowRight01;
  static const AppIconData expanded = HugeIcons.strokeRoundedArrowDown01;
  static const AppIconData send = HugeIcons.strokeRoundedArrowUp02;
  static const AppIconData close = HugeIcons.strokeRoundedCancel01;
  static const AppIconData dismiss = HugeIcons.strokeRoundedCancelCircle;
  static const AppIconData add = HugeIcons.strokeRoundedAdd01;
  static const AppIconData remove = HugeIcons.strokeRoundedRemoveCircle;
  static const AppIconData delete = HugeIcons.strokeRoundedDelete02;
  static const AppIconData edit = HugeIcons.strokeRoundedEdit02;
  static const AppIconData save = HugeIcons.strokeRoundedFloppyDisk;
  static const AppIconData copy = HugeIcons.strokeRoundedCopy01;
  static const AppIconData selectText =
      HugeIcons.strokeRoundedCursorAddSelection01;
  static const AppIconData more = HugeIcons.strokeRoundedMoreHorizontal;
  static const AppIconData search = HugeIcons.strokeRoundedSearch01;
  static const AppIconData webSearch = HugeIcons.strokeRoundedGlobe02;
  static const AppIconData webRead = HugeIcons.strokeRoundedBrowser;
  static const AppIconData settings = HugeIcons.strokeRoundedSettings02;
  static const AppIconData preferences =
      HugeIcons.strokeRoundedSlidersHorizontal;
  static const AppIconData theme = HugeIcons.strokeRoundedSunMoon;
  static const AppIconData language = HugeIcons.strokeRoundedLanguageCircle;
  static const AppIconData rendering = HugeIcons.strokeRoundedBlur;
  static const AppIconData animation = HugeIcons.strokeRoundedPlay;
  static const AppIconData ai = HugeIcons.strokeRoundedAiSparkles;
  static const AppIconData aiIdle = HugeIcons.strokeRoundedAiSparkles;
  static const AppIconData memory = HugeIcons.strokeRoundedCards02;
  static const AppIconData chat = HugeIcons.strokeRoundedMessage02;
  static const AppIconData profile = HugeIcons.strokeRoundedBlackHole01;
  static const AppIconData storage = HugeIcons.strokeRoundedDatabase02;
  static const AppIconData info = HugeIcons.strokeRoundedInformationCircle;
  static const AppIconData appVersion = HugeIcons.strokeRoundedSoftware;
  static const AppIconData updateDate = HugeIcons.strokeRoundedCalendar03;
  static const AppIconData agreement = HugeIcons.strokeRoundedAgreement01;
  static const AppIconData website = HugeIcons.strokeRoundedGlobe02;
  static const AppIconData warning = HugeIcons.strokeRoundedAlert02;
  static const AppIconData error = HugeIcons.strokeRoundedAlertCircle;
  static const AppIconData success = HugeIcons.strokeRoundedCheckmarkCircle02;
  static const AppIconData checked = HugeIcons.strokeRoundedCheckmarkSquare02;
  static const AppIconData unchecked = HugeIcons.strokeRoundedSquare;
  static const AppIconData checklist = HugeIcons.strokeRoundedTask01;
  static const AppIconData file = HugeIcons.strokeRoundedFile02;
  static const AppIconData folder = HugeIcons.strokeRoundedFolder01;
  static const AppIconData image = HugeIcons.strokeRoundedImage02;
  static const AppIconData imageUnavailable =
      HugeIcons.strokeRoundedImageNotFound01;
  static const AppIconData addImage = HugeIcons.strokeRoundedImageAdd01;
  static const AppIconData album = HugeIcons.strokeRoundedAlbum02;
  static const AppIconData play = HugeIcons.strokeRoundedPlay;
  static const AppIconData refresh = HugeIcons.strokeRoundedRefresh;
  static const AppIconData history = HugeIcons.strokeRoundedTimeQuarterPass;
  static const AppIconData server = HugeIcons.strokeRoundedServerStack01;
  static const AppIconData api = HugeIcons.strokeRoundedApi;
  static const AppIconData components = HugeIcons.strokeRoundedGridView;
  static const AppIconData logs = HugeIcons.strokeRoundedSourceCode;
}
