// Small shim main.dart so `flutter run` finds the default entrypoint.
// This forwards to the existing main() in get_started_module.dart.
import 'get_started_module.dart' as start;

void main() => start.main();
