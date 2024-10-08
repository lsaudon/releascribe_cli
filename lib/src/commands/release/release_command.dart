import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:process/process.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:releascribe_cli/src/commands/release/commit_category.dart';
import 'package:releascribe_cli/src/commands/release/commit_category_registry.dart';
import 'package:releascribe_cli/src/commands/release/conventional_commit.dart';
import 'package:releascribe_cli/src/commands/release/output/output_adapter.dart';
import 'package:releascribe_cli/src/commands/release/release_info.dart';
import 'package:releascribe_cli/src/commands/release/semantic_version_type.dart';
import 'package:releascribe_cli/src/commands/release/version/version_pub_adapter.dart';
import 'package:releascribe_cli/src/commands/release/version_control/version_control_git_adapter.dart';

/// {@template release_command}
/// A [Command] for managing releases.
///
/// Example usage:
/// ```sh
/// releascribe_cli release
/// ```
/// {@endtemplate}
class ReleaseCommand extends Command<int> {
  /// {@macro release_command}
  ReleaseCommand({
    required final ProcessManager processManager,
    required final FileSystem fileSystem,
  })  : _processManager = processManager,
        _fileSystem = fileSystem {
    argParser.addOption(
      optionReleaseInfoFile,
      abbr: 'r',
      help: 'Path to a JSON file containing release information.',
    );
  }

  @override
  String get description => 'A CLI command for managing software releases.';

  @override
  String get name => 'release';

  final optionReleaseInfoFile = 'release-info-file';

  final ProcessManager _processManager;
  final FileSystem _fileSystem;

  @override
  Future<int> run() async {
    final releaseInfo = await _parseReleaseInfoFile();
    final versionControlPort = VersionControlGitAdapter(
      processManager: _processManager,
    );
    final commits = await versionControlPort.getCommits();

    final commitCategoryRegistry =
        CommitCategoryRegistry(types: releaseInfo?.categories);
    final messagesByTypes = <CommitCategory, List<ConventionalCommit>>{};
    final commitTypeRegex = RegExp(
      r'^(?<type>[a-zA-Z]*)(\((?<scope>[a-zA-Z]*)\))?: (?<subject>.*)$',
    );
    for (final commit in commits.map((final e) => e.message)) {
      final match = commitTypeRegex.firstMatch(commit);
      final type = match?.namedGroup('type');
      final scope = match?.namedGroup('scope');
      final subject = match?.namedGroup('subject');
      final commitType = commitCategoryRegistry.findByKey(type!);
      messagesByTypes
          .putIfAbsent(commitType, () => [])
          .add(ConventionalCommit(scope: scope, subject: subject!));
    }
    final versionPort = VersionPubAdapter(fileSystem: _fileSystem);
    final currentVersion = await versionPort.getCurrentVersion();
    final version = _getNextVersion(
      currentVersion,
      messagesByTypes.keys.map((final e) => e.version).toList(),
    );
    await versionPort.setVersion(version);
    final content = _generate(
      commitCategoryRegistry: commitCategoryRegistry,
      version: version,
      messagesByType: messagesByTypes,
    );
    final outputPort = OutputAdapter(fileSystem: _fileSystem);
    await outputPort.write(
      output: releaseInfo?.output ??
          [const Output(path: 'CHANGELOG.md', overwrite: false)],
      content: content,
    );
    return ExitCode.success.code;
  }

  Future<ReleaseInfo?> _parseReleaseInfoFile() async {
    if (argResults?.options.contains(optionReleaseInfoFile) ?? false) {
      final jsonFilePath = argResults?[optionReleaseInfoFile] as String;
      final jsonFile = _fileSystem.file(jsonFilePath);
      if (await jsonFile.exists()) {
        final jsonString = await jsonFile.readAsString();
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        return ReleaseInfo.fromJson(jsonData);
      }
    }

    return null;
  }

  Version _getNextVersion(
    final Version currentVersion,
    final List<SemanticVersionType> versionTypes,
  ) {
    final highestVersionType =
        versionTypes.reduce((final a, final b) => a.index > b.index ? a : b);
    final version = _calculateNextVersion(currentVersion, highestVersionType);
    return _incrementBuildNumberIfNeeded(version, currentVersion);
  }

  Version _calculateNextVersion(
    final Version currentVersion,
    final SemanticVersionType highestVersionType,
  ) {
    switch (highestVersionType) {
      case SemanticVersionType.major:
        return currentVersion.nextMajor;
      case SemanticVersionType.minor:
        return currentVersion.nextMinor;
      case SemanticVersionType.patch:
        return currentVersion.nextPatch;
    }
  }

  Version _incrementBuildNumberIfNeeded(
    final Version version,
    final Version currentVersion,
  ) {
    final firstOrNull = currentVersion.build.firstOrNull ?? '';
    final buildNumber = int.tryParse(firstOrNull.toString());

    if (buildNumber == null) {
      return version;
    }

    return Version(
      version.major,
      version.minor,
      version.patch,
      build: '${buildNumber + 1}',
    );
  }

  String _generate({
    required final CommitCategoryRegistry commitCategoryRegistry,
    required final Version version,
    required final Map<CommitCategory, List<ConventionalCommit>> messagesByType,
  }) {
    final buffer = StringBuffer('## 🔖 [$version]\n');

    for (final type in commitCategoryRegistry.types) {
      final messages = messagesByType[type];
      if (messages != null) {
        buffer.writeln('\n### ${type.label}\n');
        for (final message in messages) {
          final scope = message.scope != null ? '**${message.scope}:** ' : '';
          buffer.writeln(
            '- $scope${message.subject}',
          );
        }
      }
    }

    return buffer.toString();
  }
}
