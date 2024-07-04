import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:process/process.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:releascribe_cli/src/command_runner.dart';
import 'package:test/test.dart';

// Mock Classes
class _MockLogger extends Mock implements Logger {}

class _MockPubUpdater extends Mock implements PubUpdater {}

class _MockProcessManager extends Mock implements ProcessManager {}

// Constants for Test Data
const changelogContent = '''
## 🔖 [1.3.0+2]

### 🐛 Bug Fixes

- fixed authentication

### ✨ Features

- added performance benchmark
- **Profile:** added profile page

### ♻️ Code Refactoring

- optimized user profile

### ⚡️ Performance Improvements

- refactored login page

### 🧪 Tests

- updated testing framework

### 📝 Documentation

- updated README file

### 🧱 Build

- created database connection

### 🎞️ Workflow

- updated CI/CD pipeline

### 🧹 Chores

- removed CI/CD pipeline
- removed testing framework
''';
const String changelogContentFromJsonFile = '''
## 🔖 [1.3.0+2]

### 🐛 Corrections de bugs

- fixed authentication

### ✨ Fonctionnalités

- added performance benchmark
- **Profile:** added profile page

### ♻️ Refonte du code

- optimized user profile

### ⚡️ Amélioration des performances

- refactored login page

### 🧪 Tests

- updated testing framework

### 📝 Documentation

- updated README file

### 🧱 Construction

- created database connection

### 🎞️ Flux de travail

- updated CI/CD pipeline

### 🧹 Tâches

- removed CI/CD pipeline
- removed testing framework
''';

const String helpMessage = '''
Usage: $executableName release [arguments]
-h, --help                 Print this usage information.
-r, --release-info-file    Path to a JSON file containing release information.

Run "$executableName help" to see global options.''';

const String pubspecContent = '''
name: example
version: 1.2.3+1
environment:
  sdk: ">=3.0.0 <4.0.0"''';

const String updatedPubspecContent = '''
name: example
version: 1.3.0+2
environment:
  sdk: ">=3.0.0 <4.0.0"''';

// Helper Function to Create File System
MemoryFileSystem _createTestFileSystem() {
  final fileSystem = MemoryFileSystem.test(
    style: Platform.isWindows ? FileSystemStyle.windows : FileSystemStyle.posix,
  );

  fileSystem.file('pubspec.yaml')
    ..createSync()
    ..writeAsStringSync(pubspecContent);
  return fileSystem;
}

final commitResult = ProcessResult(
  0,
  0,
  '''
fix: fixed authentication
feat: added performance benchmark
feat(Profile): added profile page
test: updated testing framework
docs: updated README file
chore: removed CI/CD pipeline
refactor: optimized user profile
build: created database connection
perf: refactored login page
chore: removed testing framework
ci: updated CI/CD pipeline
''',
  '',
);

// Helper Function to Mock Process Results for No Tag Scenario
void _mockProcessResultsForNoTag(final ProcessManager processManager) {
  final noTagResult = ProcessResult(
    0,
    128,
    '',
    'fatal : Aucun nom trouvé, impossible de décrire quoi que ce soit.',
  );

  when(() => processManager.run('git describe --tags --abbrev=0'.split(' ')))
      .thenAnswer((final _) async => noTagResult);
  when(
    () => processManager.run('git log HEAD --grep=^.*: --pretty=%s'.split(' ')),
  ).thenAnswer((final _) async => commitResult);
}

// Helper Function to Mock Process Results for Latest Tag Scenario
void _mockProcessResultsForLatestTag(final ProcessManager processManager) {
  final latestTagResult = ProcessResult(0, 0, 'v1.2.3+1', '');

  when(() => processManager.run('git describe --tags --abbrev=0'.split(' ')))
      .thenAnswer((final _) async => latestTagResult);
  when(
    () => processManager
        .run('git log v1.2.3+1..HEAD --grep=^.*: --pretty=%s'.split(' ')),
  ).thenAnswer((final _) async => commitResult);
}

void main() {
  group('release', () {
    late Logger logger;
    late ReleascribeCliCommandRunner commandRunner;
    late ProcessManager processManager;
    late FileSystem fileSystem;

    setUp(() {
      logger = _MockLogger();
      processManager = _MockProcessManager();
      const versionTag = 'v1.3.0+2';
      const versionBranch = 'releascribe-$versionTag';
      when(
        () => processManager.run(['git', 'checkout', '-b', versionBranch]),
      ).thenAnswer((final _) async => ProcessResult(0, 0, '', ''));
      when(
        () =>
            processManager.run(['git', 'add', 'pubspec.yaml', 'CHANGELOG.md']),
      ).thenAnswer((final _) async => ProcessResult(0, 0, '', ''));
      when(
        () => processManager.run(['git', 'commit', '-m', 'chore: $versionTag']),
      ).thenAnswer((final _) async => ProcessResult(0, 0, '', ''));
      when(
        () => processManager.run(
          ['git', 'push', '--atomic', 'origin', versionBranch, versionTag],
        ),
      ).thenAnswer((final _) async => ProcessResult(0, 0, '', ''));

      final pubUpdater = _MockPubUpdater();

      when(() => pubUpdater.getLatestVersion(any()))
          .thenAnswer((final _) async => '0.0.1');

      fileSystem = _createTestFileSystem();

      commandRunner = ReleascribeCliCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
        processManager: processManager,
        fileSystem: fileSystem,
      );
    });

    Future<void> runReleaseAndValidateChangelog(
      final ReleascribeCliCommandRunner commandRunner,
      final FileSystem fileSystem, {
      final Iterable<String> args = const ['release'],
      final String changeLogExpected = changelogContent,
    }) async {
      final exitCode = await commandRunner.run(args);
      expect(exitCode, ExitCode.success.code);

      final pubspecFile = await fileSystem.file('pubspec.yaml').readAsString();
      expect(pubspecFile, updatedPubspecContent);

      final changelogFime =
          await fileSystem.file('CHANGELOG.md').readAsString();
      expect(changelogFime, changeLogExpected);
      const versionTag = 'v1.3.0+2';
      const versionBranch = 'releascribe-$versionTag';
      for (final c in [
        ['git', 'checkout', '-b', versionBranch],
        ['git', 'add', 'pubspec.yaml', 'CHANGELOG.md'],
        ['git', 'commit', '-m', 'chore: $versionTag'],
        ['git', 'push', '--atomic', 'origin', versionBranch, versionTag],
      ]) {
        verify(() => processManager.run(c));
      }
    }

    test('generate CHANGELOG.md when no previous tags exist', () async {
      _mockProcessResultsForNoTag(processManager);

      await runReleaseAndValidateChangelog(commandRunner, fileSystem);
    });

    test('generate CHANGELOG.md when previous tag exists', () async {
      _mockProcessResultsForLatestTag(processManager);

      await runReleaseAndValidateChangelog(commandRunner, fileSystem);
    });

    test('should handle release-info-file parameter correctly', () async {
      _mockProcessResultsForLatestTag(processManager);

      final releaseInfoContent = {
        'changelog': [
          {
            'type': 'fix',
            'description': '🐛 Corrections de bugs',
            'increment': 'patch',
          },
          {
            'type': 'feat',
            'description': '✨ Fonctionnalités',
            'increment': 'minor',
          },
          {
            'type': 'refactor',
            'description': '♻️ Refonte du code',
            'increment': 'patch',
          },
          {
            'type': 'perf',
            'description': '⚡️ Amélioration des performances',
            'increment': 'patch',
          },
          {'type': 'test', 'description': '🧪 Tests', 'increment': 'patch'},
          {
            'type': 'docs',
            'description': '📝 Documentation',
            'increment': 'patch',
          },
          {
            'type': 'build',
            'description': '🧱 Construction',
            'increment': 'patch',
          },
          {
            'type': 'ci',
            'description': '🎞️ Flux de travail',
            'increment': 'patch',
          },
          {'type': 'chore', 'description': '🧹 Tâches', 'increment': 'patch'},
        ],
      };

      const releaseInfoFile = 'release-info.json';
      fileSystem.file(releaseInfoFile)
        ..createSync()
        ..writeAsStringSync(jsonEncode(releaseInfoContent));

      await runReleaseAndValidateChangelog(
        commandRunner,
        fileSystem,
        args: [
          'release',
          '--release-info-file',
          releaseInfoFile,
        ],
        changeLogExpected: changelogContentFromJsonFile,
      );
    });

    test('show error message for invalid release command', () async {
      final exitCode = await commandRunner.run(['release', '-p']);
      expect(exitCode, ExitCode.usage.code);

      verify(() => logger.err('Could not find an option or flag "-p".'));
      verify(() => logger.info(helpMessage));
    });
  });
}
