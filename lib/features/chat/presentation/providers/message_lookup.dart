import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/app_failure.dart';
import '../../data/chat_data_providers.dart';
import '../../domain/models/message.dart';

part '../../../../gen/features/chat/presentation/providers/message_lookup.g.dart';

@riverpod
Future<Either<AppFailure, Option<Message>>> messageById(Ref ref, int id) =>
    ref.watch(messageRepositoryProvider).byId(id).run();
