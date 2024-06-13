import 'package:pub_semver/pub_semver.dart';
import 'package:releascribe_cli/src/commands/release/version_control/commit.dart';

abstract interface class VersionControlPort {
  Future<List<Commit>> getCommits();
  Future<void> createVersion({required final Version version});
}
