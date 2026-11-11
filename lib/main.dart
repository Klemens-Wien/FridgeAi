import 'package:flutter/material.dart';

import 'app.dart';
import 'services/storage.dart';
import 'state/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await LocalStore.open();
  final settings = SettingsStore(store, SecureSecretStore());
  await settings.loadSecrets();
  runApp(FridgeChefApp(store: store, settings: settings));
}
