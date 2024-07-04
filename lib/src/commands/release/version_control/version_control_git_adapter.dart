import 'package:mason_logger/mason_logger.dart';
import 'package:process/process.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:releascribe_cli/src/commands/release/version_control/commit.dart';
import 'package:releascribe_cli/src/commands/release/version_control/version_control_port.dart';

class VersionControlGitAdapter implements VersionControlPort {
  VersionControlGitAdapter({
    required final Logger logger,
    required final ProcessManager processManager,
  })  : _logger = logger,
        _processManager = processManager;

  final Logger _logger;
  final ProcessManager _processManager;

  @override
  Future<List<Commit>> getCommits() async {
    final commitRange = await _getCommitRange();
    await _processManager.run(['git', 'checkout', '-b', 'temp']);
    final result = await _processManager
        .run(['git', 'log', commitRange, '--grep=^.*:', '--pretty=%s']);
    if (result.exitCode != ExitCode.success.code) {
      return [];
    }

    return (result.stdout as String)
        .split('\n')
        .where((final e) => e.isNotEmpty)
        .map((final e) => Commit(message: e))
        .toList();
  }

  Future<String> _getCommitRange() async {
    final result =
        await _processManager.run(['git', 'describe', '--tags', '--abbrev=0']);

    if (result.exitCode != ExitCode.success.code) {
      return 'HEAD';
    }

    return '${result.stdout as String}..HEAD';
  }

  @override
  Future<void> createVersion({required final Version version}) async {
    final versionTag = 'v$version';
    final branchName = 'releascribe-$versionTag';
    await _processManager.run(['git', 'checkout', '-b', branchName]);
    await _processManager.run(['git', 'add', 'pubspec.yaml', 'CHANGELOG.md']);
    await _processManager.run(['git', 'commit', '-m', 'chore: $versionTag']);
    await _processManager
        .run(['git', 'push', '--atomic', 'origin', branchName]);
    _logger.info('Branch $branchName created.');
  }
}
