// Web is the default so WASM, which has no dart:io, never loads the plugin-based version.
export 'platform_services_web.dart'
    if (dart.library.io) 'platform_services_io.dart';
