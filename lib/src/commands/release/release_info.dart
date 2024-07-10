import 'package:releascribe_cli/src/commands/release/commit_category.dart';
import 'package:releascribe_cli/src/commands/release/semantic_version_type.dart';

final class ReleaseInfo {
  const ReleaseInfo({required this.output, required this.categories});

  ReleaseInfo.fromJson(final Map<String, dynamic> json)
      : this(
          categories: (json['changelog'] as List<dynamic>).map((final element) {
            final e = element as Map<String, dynamic>;
            return CommitCategory(
              e['type'] as String,
              e['description'] as String,
              SemanticVersionType.values.firstWhere(
                (final f) => f.name == e['increment'] as String,
              ),
            );
          }).toList(),
          output: (json['output'] as List<dynamic>).map((final element) {
            final e = element as Map<String, dynamic>;
            return Output(
              path: e['path'] as String,
              overwrite: e['overwrite'] as bool,
            );
          }).toList(),
        );

  final List<Output> output;
  final List<CommitCategory> categories;
}

final class Output {
  const Output({required this.path, required this.overwrite});

  final String path;
  final bool overwrite;
}
