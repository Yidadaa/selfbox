import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/chat_data_providers.dart';
import '../../domain/models/message.dart';

part '../../../../gen/features/chat/presentation/providers/pinned_messages.g.dart';

@riverpod
Stream<List<Message>> pinnedMessages(Ref ref) =>
    ref.watch(messageRepositoryProvider).watchPinned();
