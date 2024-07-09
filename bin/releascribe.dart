import 'dart:io';

import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:process/process.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:releascribe_cli/src/command_runner.dart';

Future<void> main(final List<String> args) async {
  await _flushThenExit(
    await ReleascribeCliCommandRunner(
      logger: Logger(),
      pubUpdater: PubUpdater(),
      processManager: const LocalProcessManager(),
      fileSystem: const LocalFileSystem(),
    ).run(args),
  );
}

/// Flushes the stdout and stderr streams, then exits the program with the given
/// status code.
///
/// This returns a Future that will never complete, since the program will have
/// exited already. This is useful to prevent Future chains from proceeding
/// after you've decided to exit.
Future<void> _flushThenExit(final int status) =>
    Future.wait<void>(<Future<void>>[stdout.close(), stderr.close()])
        .then<void>((final _) => exit(status));
