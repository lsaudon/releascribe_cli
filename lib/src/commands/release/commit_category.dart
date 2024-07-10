import 'package:releascribe_cli/src/commands/release/semantic_version_type.dart';

final class CommitCategory {
  const CommitCategory(this.key, this.label, this.version);

  final String key;
  final String label;
  final SemanticVersionType version;
}
