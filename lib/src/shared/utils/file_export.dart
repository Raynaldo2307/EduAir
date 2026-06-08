// Cross-platform file export.
//
// Exports a single `exportFile(...)` function. The compiler swaps the
// implementation based on the target platform:
//   • web   → file_export_web.dart  (dart:html browser download)
//   • mobile/desktop → file_export_io.dart  (temp file + share sheet)
//
// This is the conditional-import pattern: dart:html never reaches a mobile
// build and dart:io never reaches a web build, so the app compiles everywhere.
export 'file_export_io.dart'
    if (dart.library.html) 'file_export_web.dart';
