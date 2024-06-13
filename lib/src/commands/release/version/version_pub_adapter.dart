import 'package:file/file.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:releascribe_cli/src/commands/release/version/version_port.dart';

const _pattern = 'version: ';
const _path = 'pubspec.yaml';

class VersionPubAdapter implements VersionPort {
  VersionPubAdapter({required final FileSystem fileSystem})
      : _fileSystem = fileSystem;

  final FileSystem _fileSystem;

  @override
  Future<Version> getCurrentVersion() async {
    final file = await _fileSystem.file(_path).readAsString();
    final pubspec = Pubspec.parse(file);
    return pubspec.version ?? Version.none;
  }

  @override
  Future<void> setVersion(final Version version) async {
    final pubspecAsLines = await _fileSystem.file(_path).readAsLines();
    final versionIndex =
        pubspecAsLines.indexWhere((final e) => e.startsWith(_pattern));
    pubspecAsLines[versionIndex] = '$_pattern$version';
    final pubspecAsString = pubspecAsLines
        .reduce((final value, final element) => '$value\n$element');
    await _fileSystem.file(_path).writeAsString(pubspecAsString);
  }
}
