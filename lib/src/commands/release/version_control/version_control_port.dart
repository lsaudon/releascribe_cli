import 'package:releascribe_cli/src/commands/release/version_control/commit.dart';

abstract interface class VersionControlPort {
  Future<List<Commit>> getCommits();
}
