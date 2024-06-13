import 'package:pub_semver/pub_semver.dart';

abstract interface class VersionPort {
  Future<Version> getCurrentVersion();

  Future<void> setVersion(final Version version);
}
