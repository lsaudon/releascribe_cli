import 'package:releascribe_cli/src/commands/release/commit_category.dart';
import 'package:releascribe_cli/src/commands/release/semantic_version_type.dart';

final class CommitCategoryRegistry {
  const CommitCategoryRegistry({final List<CommitCategory>? types})
      : _types = types ??
            const [
              CommitCategory(
                'fix',
                '🐛 Bug Fixes',
                SemanticVersionType.patch,
              ),
              CommitCategory(
                'feat',
                '✨ Features',
                SemanticVersionType.minor,
              ),
              CommitCategory(
                'refactor',
                '♻️ Code Refactoring',
                SemanticVersionType.patch,
              ),
              CommitCategory(
                'perf',
                '⚡️ Performance Improvements',
                SemanticVersionType.patch,
              ),
              CommitCategory('test', '🧪 Tests', SemanticVersionType.patch),
              CommitCategory(
                'docs',
                '📝 Documentation',
                SemanticVersionType.patch,
              ),
              CommitCategory(
                'build',
                '🧱 Build',
                SemanticVersionType.patch,
              ),
              CommitCategory(
                'ci',
                '🎞️ Workflow',
                SemanticVersionType.patch,
              ),
              CommitCategory('chore', '🧹 Chores', SemanticVersionType.patch),
            ];

  final List<CommitCategory> _types;

  List<CommitCategory> get types => List<CommitCategory>.unmodifiable(_types);

  CommitCategory findByKey(final String key) => _types.firstWhere(
        (final type) => type.key == key,
        orElse: () => const CommitCategory('', '', SemanticVersionType.patch),
      );
}
