import 'package:file/file.dart';
import 'package:releascribe_cli/src/commands/release/output/output_port.dart';
import 'package:releascribe_cli/src/commands/release/release_info.dart';

class OutputAdapter implements OutputPort {
  OutputAdapter({required final FileSystem fileSystem})
      : _fileSystem = fileSystem;

  final FileSystem _fileSystem;

  @override
  Future<void> write({
    required final String content,
    required final List<Output> output,
  }) async {
    for (final e in output) {
      final file = _fileSystem.file(e.path);
      if (await file.exists() && !e.overwrite) {
        final oldChangeLog = await file.readAsString();
        await file.writeAsString('$content\n$oldChangeLog');
      } else {
        await file.writeAsString(content);
      }
    }
  }
}
