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
    final checkout =
        await _processManager.run(['git', 'checkout', '-b', branchName]);
    if (checkout.exitCode != ExitCode.success.code) {
      _logger.err('Failed to create branch $branchName.');
      return;
    }
    final addFiles = await _processManager
        .run(['git', 'add', 'pubspec.yaml', 'CHANGELOG.md']);
    if (addFiles.exitCode != ExitCode.success.code) {
      _logger.err('Failed to add files to commit.');
      return;
    }
    final commit = await _processManager
        .run(['git', 'commit', '-m', 'chore: $versionTag']);
    if (commit.exitCode != ExitCode.success.code) {
      _logger.err('Failed to commit changes.');
      return;
    }
    final push = await _processManager
        .run(['git', 'push', '--set-upstream', 'origin', branchName]);
    if (push.exitCode != ExitCode.success.code) {
      _logger.err('Failed to push branch $branchName.');
      return;
    }
    _logger.info('Branch $branchName created.');
  }
}
