import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_failure.dart';
import '../models/message.dart';
import '../repositories/message_repository.dart';
import 'agent_prompt.dart';

const _pageSize = 64;

/// Fills a contiguous recent window, including the current question. Older
/// notes remain reachable through tools rather than skipping gaps in history.
TaskEither<AppFailure, List<Message>> loadAgentHistory({
  required MessageRepository messages,
  required Message question,
  required int budget,
}) => TaskEither(() {
  final kept = <Message>[question];
  final seen = <int>{question.id};

  TaskEither<AppFailure, List<Message>> readPage(int offset, int remaining) {
    if (remaining <= 0) return TaskEither.right(List.unmodifiable(kept));
    return messages.latest(_pageSize, offset: offset).flatMap((page) {
      var available = remaining;
      for (final message in page) {
        if (seen.contains(message.id) ||
            message.createdAt.isAfter(question.createdAt) ||
            (message.createdAt == question.createdAt &&
                message.id > question.id)) {
          continue;
        }
        final cost = estimateMessageTokens(message);
        if (cost > available) return TaskEither.right(List.unmodifiable(kept));
        kept.add(message);
        seen.add(message.id);
        available -= cost;
      }
      return page.length < _pageSize
          ? TaskEither.right(List.unmodifiable(kept))
          : readPage(offset + page.length, available);
    });
  }

  return readPage(0, budget - estimateMessageTokens(question)).run();
});
