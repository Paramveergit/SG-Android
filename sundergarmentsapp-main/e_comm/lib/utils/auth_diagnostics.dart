// ignore_for_file: file_names

/// Captures the actual Firebase Auth state at key moments, so if a
/// person lands on Sign-In unexpectedly (session should have
/// persisted but didn't), the real data is visible on-screen instead
/// of buried in adb logcat that most people testing this app can't
/// easily pull. Two fix attempts based on a timing-race theory didn't
/// resolve this reported issue - that theory needs to be confirmed or
/// ruled out with real data before guessing a third time.
class AuthDiagnostics {
  AuthDiagnostics._();

  /// Firebase Auth's currentUser, captured as early as physically
  /// possible - immediately after Firebase.initializeApp() in main(),
  /// before any of this app's own routing/controller logic runs.
  static String? t0Uid;
  static DateTime? t0Timestamp;

  /// Step-by-step trace of what HomeRouter actually saw while
  /// deciding where to route - each entry is one decision point.
  static final List<String> homeRouterTrace = [];

  static void log(String entry) {
    homeRouterTrace.add('${DateTime.now().toIso8601String().substring(11, 23)}  $entry');
  }

  static String summary() {
    final buffer = StringBuffer();
    buffer.writeln('t0 (main.dart, right after Firebase.initializeApp):');
    buffer.writeln('  currentUser = ${t0Uid ?? "null"}');
    buffer.writeln('  captured at = ${t0Timestamp?.toIso8601String() ?? "?"}');
    buffer.writeln();
    buffer.writeln('HomeRouter trace:');
    if (homeRouterTrace.isEmpty) {
      buffer.writeln('  (empty - HomeRouter never ran, or was cleared)');
    } else {
      for (final entry in homeRouterTrace) {
        buffer.writeln('  $entry');
      }
    }
    return buffer.toString();
  }
}
