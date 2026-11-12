part of 'agent_tools.dart';

extension _AgentToolSupport on AgentTools {
  Future<Object?> _withPath(
    ToolInput input,
    TaskEither<AppFailure, Map<String, Object?>> Function(MemoryPath) run,
  ) => MemoryPath.parse(_str(input['path']) ?? '')
      .match((f) async => _error(_describe(f)), (path) => _answer(run(path)));

  Tool<ToolInput, Object?> _tool(
    String name,
    String description,
    Map<String, Object?> properties,
    Future<Object?> Function(ToolInput input, String toolCallId) run, {
    List<String> required = const [],
  }) => tool<ToolInput, Object?>(
    description: description,
    inputSchema: Schema<ToolInput>(
      jsonSchema: {
        'type': 'object',
        'properties': properties,
        'required': required,
        'additionalProperties': false,
      },
      fromJson: Map<String, Object?>.of,
    ),
    execute: (input, options) async {
      final result = await run(input, options.toolCallId ?? '');
      onResult?.call(
        name,
        result is! Map<String, Object?> || !result.containsKey('error'),
      );
      return result;
    },
  );
}

Future<Object?> _answer(
  TaskEither<AppFailure, Map<String, Object?>> task,
) async => (await task.run()).match((f) => _error(_describe(f)), (ok) => ok);

Map<String, Object?> _error(String message) => {'error': message};

String _describe(AppFailure failure) => switch (failure) {
  ValidationFailure(:final message) ||
  DatabaseFailure(:final message) ||
  NetworkFailure(:final message) => message,
  PermissionFailure(:final permission) => 'permission denied: $permission',
  UnexpectedFailure(:final error) => error.toString(),
};

Map<String, Object?> _messageJson(Message m, {required int maxText}) => {
  'id': m.id,
  'time': _iso(m.createdAt),
  'author': m.author.name,
  'text': _truncate(m.text, maxText),
  if (m.images.isNotEmpty) 'images': m.images.length,
};

String _iso(DateTime t) =>
    t.toLocal().toIso8601String().substring(0, 16).replaceFirst('T', ' ');

String _truncate(String text, int max) =>
    text.length <= max ? text : '${text.substring(0, max)}…';

String? _str(Object? value) => value is String ? value : null;

int? _intOf(Object? value) => switch (value) {
  final int v => v,
  final double v when v == v.roundToDouble() => v.toInt(),
  final String v => int.tryParse(v),
  _ => null,
};

DateTime? _date(Object? value, {bool endOfDay = false}) {
  final parsed = DateTime.tryParse(_str(value) ?? '');
  if (parsed == null) return null;
  final dateOnly = (_str(value) ?? '').length <= 10;
  return endOfDay && dateOnly
      ? parsed.add(const Duration(days: 1, microseconds: -1))
      : parsed;
}

String _mediaType(String path) => switch (p.extension(path)) {
  '.png' => 'image/png',
  '.gif' => 'image/gif',
  '.webp' => 'image/webp',
  '.heic' => 'image/heic',
  _ => 'image/jpeg',
};

Map<String, Object?> _string(String description) => {
  'type': 'string',
  'description': description,
};

Map<String, Object?> _int(String description) => {
  'type': 'integer',
  'description': description,
};
