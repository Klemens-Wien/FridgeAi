import 'package:flutter/material.dart';

import 'app.dart';
import 'services/ai_backend.dart';
import 'services/claude_client.dart';
import 'services/fridge_ai_service.dart';
import 'services/storage.dart';
import 'services/web_ai_stub.dart'
    if (dart.library.js_interop) 'services/web_ai_web.dart';
import 'state/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await LocalStore.open();
  final settings = SettingsStore(store, SecureSecretStore());
  await settings.loadSecrets();

  // On the web inside claude.ai, Claude is available without an API key.
  AiBackend? builtIn;
  loadBuiltInAi().then((backend) {
    if (backend == null) return;
    builtIn = backend;
    settings.setBuiltInAi(true);
  });

  runApp(FridgeChefApp(
    store: store,
    settings: settings,
    aiFactory: (apiKey) =>
        FridgeAiService(builtIn ?? ClaudeClient(apiKey: apiKey)),
  ));
}
