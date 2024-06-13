import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:process/process.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:releascribe_cli/src/command_runner.dart';
import 'package:releascribe_cli/src/version.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _MockPubUpdater extends Mock implements PubUpdater {}

class _MockProcessManager extends Mock implements ProcessManager {}

const String latestVersion = '0.0.0';

final String updatePrompt = '''
${lightYellow.wrap('Update available!')} ${lightCyan.wrap(packageVersion)} \u2192 ${lightCyan.wrap(latestVersion)}
Run ${lightCyan.wrap('$executableName update')} to update''';

void main() {
  group('ReleascribeCliCommandRunner', () {
    late PubUpdater pubUpdater;
    late Logger logger;
    late ProcessManager processManager;
    late ReleascribeCliCommandRunner commandRunner;

    setUp(() {
      pubUpdater = _MockPubUpdater();

      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((final invocation) async => packageVersion);

      logger = _MockLogger();
      processManager = _MockProcessManager();

      final mfs = MemoryFileSystem.test(
        style: Platform.isWindows
            ? FileSystemStyle.windows
            : FileSystemStyle.posix,
      );

      mfs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync('''
name: example
version: 1.0.0+1
environment:
  sdk: ">=2.19.2 <3.0.0"''');

      commandRunner = ReleascribeCliCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
        processManager: processManager,
        fileSystem: mfs,
      );
    });

    test('shows update message when newer version exists', () async {
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((final _) async => latestVersion);

      final result = await commandRunner.run(<String>['--version']);
      expect(result, equals(ExitCode.success.code));
      verify(() => logger.info(updatePrompt));
    });

    test(
      'Does not show update message when the shell calls the '
      'completion command',
      () async {
        when(
          () => pubUpdater.getLatestVersion(any()),
        ).thenAnswer((final _) async => latestVersion);

        final result = await commandRunner.run(<String>['completion']);
        expect(result, equals(ExitCode.success.code));
        verifyNever(() => logger.info(updatePrompt));
      },
    );

    test('does not show update message when using update command', () async {
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((final _) async => latestVersion);
      when(
        () => pubUpdater.update(
          packageName: packageName,
          versionConstraint: any(named: 'versionConstraint'),
        ),
      ).thenAnswer(
        (final _) async => ProcessResult(0, ExitCode.success.code, null, null),
      );
      when(
        () => pubUpdater.isUpToDate(
          packageName: any(named: 'packageName'),
          currentVersion: any(named: 'currentVersion'),
        ),
      ).thenAnswer((final _) async => true);

      final progress = _MockProgress();
      final progressLogs = <String>[];
      when(() => progress.complete(any())).thenAnswer(
        (final invocation) {
          {
            final message =
                invocation.positionalArguments.elementAt(0) as String?;
            if (message != null) {
              progressLogs.add(message);
            }
          }
        },
      );
      when(() => logger.progress(any())).thenReturn(progress);

      final result = await commandRunner.run(<String>['update']);
      expect(result, equals(ExitCode.success.code));
      verifyNever(() => logger.info(updatePrompt));
    });

    test('handles FormatException', () async {
      const exception = FormatException('oops!');
      var isFirstInvocation = true;
      when(() => logger.info(any())).thenAnswer((final _) {
        if (isFirstInvocation) {
          isFirstInvocation = false;
          throw exception;
        }
      });
      final result = await commandRunner.run(<String>['--version']);
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err(exception.message));
      verify(() => logger.info(commandRunner.usage));
    });

    test('handles UsageException', () async {
      final exception = UsageException('oops!', 'exception usage');
      var isFirstInvocation = true;
      when(() => logger.info(any())).thenAnswer((final _) {
        if (isFirstInvocation) {
          isFirstInvocation = false;
          throw exception;
        }
      });
      final result = await commandRunner.run(<String>['--version']);
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err(exception.message));
      verify(() => logger.info('exception usage'));
    });

    group('--version', () {
      test('outputs current version', () async {
        final result = await commandRunner.run(<String>['--version']);
        expect(result, equals(ExitCode.success.code));
        verify(() => logger.info(packageVersion));
      });
    });

    group('--verbose', () {
      test('enables verbose logging', () async {
        final result = await commandRunner.run(<String>['--verbose']);
        expect(result, equals(ExitCode.success.code));

        verify(() => logger.detail('Argument information:'));
        verify(() => logger.detail('  Top level options:'));
        verify(() => logger.detail('  - verbose: true'));
        verifyNever(() => logger.detail('    Command options:'));
      });

      test('enables verbose logging for sub commands', () async {
        when(() => processManager.run(any())).thenAnswer(
          (final invocation) => Future.value(
            ProcessResult(42, ExitCode.success.code, 'feat: One', ''),
          ),
        );
        final result =
            await commandRunner.run(<String>['--verbose', 'release']);
        expect(result, equals(ExitCode.success.code));

        verify(() => logger.detail('Argument information:'));
        verify(() => logger.detail('  Top level options:'));
        verify(() => logger.detail('  - verbose: true'));
        verify(() => logger.detail('  Command: release'));
      });
    });
  });
}
