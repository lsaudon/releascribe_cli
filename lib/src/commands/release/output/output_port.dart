import 'package:releascribe_cli/src/commands/release/release_info.dart';

abstract interface class OutputPort {
  Future<void> write({
    required final String content,
    required final List<Output> output,
  });
}
