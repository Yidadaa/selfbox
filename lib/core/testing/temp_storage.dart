import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:objectbox/objectbox.dart';

import '../database/app_store.dart';
import '../storage/app_paths.dart';

/// A fresh sandbox per test, deleted afterwards.
AppPaths createTempAppPaths() {
  final root = Directory.systemTemp.createTempSync('selfbox_test_');
  addTearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });
  return AppPaths(root);
}

/// A real ObjectBox store in a temp directory, closed after the test.
///
/// Requires the host library (`dart run tool/fetch_objectbox_native.dart`).
Future<Store> openTempStore([AppPaths? paths]) async {
  final store = await openAppStore(paths ?? createTempAppPaths());
  addTearDown(store.close);
  return store;
}

/// Deterministic, strictly increasing timestamps.
DateTime Function() steppingClock(
  DateTime start, {
  Duration step = const Duration(minutes: 1),
}) {
  var next = start;
  return () {
    final now = next;
    next = next.add(step);
    return now;
  };
}
