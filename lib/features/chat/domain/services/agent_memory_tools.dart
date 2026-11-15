part of 'agent_tools.dart';

extension _AgentMemoryTools on AgentTools {
  Future<Object?> _listMemory() => _answer(
    memory.list().map(
      (entries) => {
        'files': [
          for (final e in entries)
            {
              'path': e.path.value,
              'title': e.title,
              'updated': _iso(e.updatedAt),
            },
        ],
      },
    ),
  );

  Future<Object?> _readMemory(ToolInput input, String _) => _withPath(
    input,
    (path) => memory
        .read(path)
        .map(
          (file) => file.match(
            () => {'error': '${path.value} does not exist'},
            (f) => {
              'path': f.path.value,
              'content': _truncate(f.content, AgentTools.maxMemoryLength),
            },
          ),
        ),
  );

  Future<Object?> _searchMemory(ToolInput input, String _) => _answer(
    memory
        .search(_str(input['keywords']) ?? '')
        .map(
          (hits) => {
            'hits': [
              for (final h in hits)
                {'path': h.path.value, 'line': h.line, 'text': h.text},
            ],
          },
        ),
  );

  Future<Object?> _createMemory(ToolInput input, String _) => _withPath(
    input,
    (path) => memory
        .create(path, _str(input['content']) ?? '')
        .map((f) => {'ok': true, 'path': f.path.value}),
  );

  Future<Object?> _patchMemory(ToolInput input, String _) => _withPath(
    input,
    (path) => memory
        .patch(path, _str(input['diff']) ?? '')
        .map((f) => {'ok': true, 'path': f.path.value, 'content': f.content}),
  );

  Future<Object?> _deleteMemory(ToolInput input, String _) =>
      _withPath(input, (path) => memory.delete(path).map((_) => {'ok': true}));
}
