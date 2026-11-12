import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../l10n/strings.dart';
import '../../models/food_log.dart';
import '../../models/pantry_item.dart' show dateOnly;
import '../../services/claude_client.dart';
import '../../services/image_utils.dart';
import '../../state/food_log_store.dart';
import '../../state/recipe_store.dart';
import '../../state/settings_store.dart';
import '../widgets/common.dart';

/// Bottom sheet to log a meal for [day]: type the values, or describe the
/// meal / add a photo and let the AI estimate them.
Future<void> showEntrySheet(BuildContext context, {required DateTime day}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _EntrySheet(day: day),
    );

/// Timestamp for a new entry on [day]: now for today, noon for other days.
DateTime entryTimeFor(DateTime day, [DateTime? now]) {
  final n = now ?? DateTime.now();
  return dateOnly(day) == dateOnly(n)
      ? n
      : dateOnly(day).add(const Duration(hours: 12));
}

class _EntrySheet extends StatefulWidget {
  const _EntrySheet({required this.day});
  final DateTime day;

  @override
  State<_EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends State<_EntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  Uint8List? _photo;
  bool _busy = false;
  bool _estimated = false;
  ClaudeException? _error;
  String? _hint;

  @override
  void dispose() {
    for (final c in [_name, _kcal, _protein, _carbs, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  static double _num(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _pickPhoto(ImageSource source) async {
    final s = context.s;
    try {
      final f = await ImagePicker().pickImage(
        source: source,
        maxWidth: AppConfig.maxImageDimension,
        maxHeight: AppConfig.maxImageDimension,
        imageQuality: 85,
      );
      if (f == null) return;
      final bytes = await f.readAsBytes();
      detectImageMediaType(bytes);
      setState(() {
        _photo = bytes;
        _hint = null;
      });
    } on UnsupportedImageException {
      if (mounted) setState(() => _hint = s.unsupportedImage);
    } catch (e) {
      debugPrint('Image picker failed: $e');
      if (mounted) setState(() => _hint = s.cameraError);
    }
  }

  Future<void> _estimate() async {
    final s = context.s;
    if (_name.text.trim().isEmpty && _photo == null) {
      setState(() => _hint = s.estimateNeedsInput);
      return;
    }
    final settings = context.read<SettingsStore>();
    final factory = context.read<AiServiceFactory>();
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _hint = null;
    });
    try {
      final estimate = await factory(settings.effectiveApiKey).estimateMeal(
        description: _name.text,
        photo: _photo,
        languageCode: s.languageCode,
      );
      if (!mounted) return;
      if (estimate == null) {
        setState(() => _hint = s.estimateFailed);
        return;
      }
      setState(() {
        if (_name.text.trim().isEmpty) _name.text = estimate.name;
        _kcal.text = '${estimate.calories.round()}';
        _protein.text = '${estimate.proteinG.round()}';
        _carbs.text = '${estimate.carbsG.round()}';
        _fat.text = '${estimate.fatG.round()}';
        _estimated = true;
      });
    } on ClaudeException catch (e) {
      if (mounted) setState(() => _error = e);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            ClaudeException(ClaudeErrorKind.badResponse, e.toString()));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<FoodLogStore>().add(FoodLogEntry(
          name: _name.text.trim(),
          calories: _num(_kcal.text),
          proteinG: _num(_protein.text),
          carbsG: _num(_carbs.text),
          fatG: _num(_fat.text),
          estimated: _estimated,
          eatenAt: entryTimeFor(widget.day),
        ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final numbers = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    final frequent = context.watch<FoodLogStore>().frequent();

    Widget gramField(TextEditingController c, String label) => Expanded(
          child: TextFormField(
            controller: c,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: numbers,
            onChanged: (_) => _estimated = false,
            decoration: InputDecoration(
              isDense: true,
              labelText: label,
              suffixText: 'g',
            ),
          ),
        );

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.newEntry, style: theme.textTheme.titleLarge),
              if (frequent.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(s.frequentMeals, style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: frequent.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ActionChip(
                      label: Text(
                        '${frequent[i].name} · ${frequent[i].calories.round()}',
                      ),
                      onPressed: () => setState(() {
                        final f = frequent[i];
                        _name.text = f.name;
                        _kcal.text = '${f.calories.round()}';
                        _protein.text = '${f.proteinG.round()}';
                        _carbs.text = '${f.carbsG.round()}';
                        _fat.text = '${f.fatG.round()}';
                        _estimated = f.estimated;
                      }),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                minLines: 1,
                decoration: InputDecoration(
                  labelText: s.entryName,
                  hintText: s.entryNameHint,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? s.nameRequired : null,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _busy ? null : _estimate,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(s.estimateWithAi),
                  ),
                  if (_photo == null) ...[
                    IconButton.outlined(
                      tooltip: s.takePhoto,
                      onPressed:
                          _busy ? null : () => _pickPhoto(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                    ),
                    IconButton.outlined(
                      tooltip: s.fromGallery,
                      onPressed:
                          _busy ? null : () => _pickPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                    ),
                  ] else
                    InputChip(
                      avatar: ClipOval(
                        child: Image.memory(
                          _photo!,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                          cacheWidth: 64,
                        ),
                      ),
                      label: Text(s.photoAdded),
                      onDeleted: () => setState(() => _photo = null),
                    ),
                ],
              ),
              if (_busy)
                AiProgress(title: s.estimating)
              else if (_error != null) ...[
                const SizedBox(height: 12),
                AiErrorCard(error: _error!, onRetry: _estimate),
              ] else if (_hint != null) ...[
                const SizedBox(height: 8),
                Text(_hint!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _kcal,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: numbers,
                onChanged: (_) => _estimated = false,
                decoration: InputDecoration(
                  labelText: s.calories,
                  suffixText: 'kcal',
                ),
                validator: (v) => _num(v ?? '') <= 0 ? s.kcalRequired : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  gramField(_protein, s.protein),
                  const SizedBox(width: 8),
                  gramField(_carbs, s.carbsShort),
                  const SizedBox(width: 8),
                  gramField(_fat, s.fat),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(s.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
