// Live, no-file-needed size scan of the running app's own installed bundle; web has no equivalent and resolves to the stub, which always returns null.
export 'app_bundle_scan_stub.dart' if (dart.library.io) 'app_bundle_scan_io.dart';
