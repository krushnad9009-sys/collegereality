import 'package:integration_test/integration_test.dart';

import '../test/flows/core_user_flows_test.dart' as flows;

/// Device integration entrypoint for core College Reality user flows.
///
/// These same flows also run on the VM via:
///   flutter test test/flows/core_user_flows_test.dart
///
/// Device run (requires a desktop/mobile toolchain):
///   flutter test integration_test/core_flows_test.dart -d windows
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  flows.main();
}