import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../l10n/strings.dart';
import '../../state/settings_store.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _keyController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final settings = context.watch<SettingsStore>();

    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            text,
            style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
          ),
        );

    final keyStatus = settings.hasUserApiKey
        ? s.apiKeyUser
        : AppConfig.apiKeyFromEnvironment.isNotEmpty
            ? s.apiKeyBuiltIn
            : s.apiKeyNotSet;

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          header(s.appearance),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto),
                  label: Text(s.themeSystem),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode),
                  label: Text(s.themeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode),
                  label: Text(s.themeDark),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (v) => settings.setThemeMode(v.first),
            ),
          ),
          header(s.language),
          RadioGroup<String?>(
            groupValue: settings.localeCode,
            onChanged: settings.setLocaleCode,
            child: Column(
              children: [
                RadioListTile<String?>(value: null, title: Text(s.languageSystem)),
                const RadioListTile<String?>(value: 'de', title: Text('Deutsch')),
                const RadioListTile<String?>(value: 'en', title: Text('English')),
              ],
            ),
          ),
          header(s.defaultServings),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: Text(s.servingsCount(settings.defaultServings)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: settings.defaultServings > 1
                      ? () => settings.setDefaultServings(settings.defaultServings - 1)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                IconButton(
                  onPressed: settings.defaultServings < 12
                      ? () => settings.setDefaultServings(settings.defaultServings + 1)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.recycling),
            title: Text(s.prioritizeExpiring),
            subtitle: Text(s.prioritizeExpiringHint),
            value: settings.prioritizeExpiring,
            onChanged: settings.setPrioritizeExpiring,
          ),
          header(s.apiKeySection),
          ListTile(
            leading: Icon(
              settings.hasApiKey ? Icons.check_circle : Icons.key_off_outlined,
              color: settings.hasApiKey ? successColor(context) : theme.colorScheme.error,
            ),
            title: Text(keyStatus),
            subtitle: Text('${AppConfig.model} · ${Uri.parse(AppConfig.baseUrl).host}'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _keyController,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: s.apiKey,
                hintText: s.apiKeyHint,
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: () async {
                    if (_keyController.text.trim().isEmpty) return;
                    await settings.setApiKey(_keyController.text);
                    _keyController.clear();
                    if (context.mounted) showSnack(context, s.apiKeySaved);
                  },
                  child: Text(s.save),
                ),
                if (settings.hasUserApiKey)
                  OutlinedButton(
                    onPressed: () async {
                      await settings.setApiKey(null);
                      if (context.mounted) showSnack(context, s.apiKeyRemoved);
                    },
                    child: Text(s.removeApiKey),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              s.apiKeyInfo,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
