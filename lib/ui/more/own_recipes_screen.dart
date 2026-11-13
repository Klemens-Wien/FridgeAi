import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../l10n/strings.dart';
import '../../logic/recipe_ranking.dart';
import '../../services/claude_client.dart';
import '../../services/image_utils.dart';
import '../../state/pantry_store.dart';
import '../../state/recipe_store.dart';
import '../../state/settings_store.dart';
import '../pro/pro_gate.dart';
import '../recipes/recipe_card.dart';
import '../widgets/common.dart';

/// Recipes the user brought in themselves (typed, pasted or photographed).
class OwnRecipesScreen extends StatelessWidget {
  const OwnRecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final store = context.watch<RecipeStore>();
    final ranker = RecipeRanker(context.watch<PantryStore>().items);
    final scheme = Theme.of(context).colorScheme;

    void import() => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          useSafeArea: true,
          builder: (_) => const _ImportSheet(),
        );

    return Scaffold(
      appBar: AppBar(title: Text(s.ownRecipes)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'importRecipe',
        onPressed: import,
        icon: const Icon(Icons.add),
        label: Text(s.importRecipe),
      ),
      body: store.own.isEmpty
          ? EmptyState(
              icon: Icons.menu_book_outlined,
              title: s.ownRecipes,
              body: s.ownRecipesEmpty,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                for (final r in store.own)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Dismissible(
                      key: ValueKey(r.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: scheme.onErrorContainer,
                        ),
                      ),
                      onDismissed: (_) {
                        store.removeOwn(r.id);
                        showSnack(
                          context,
                          s.itemDeleted(r.title),
                          actionLabel: s.undo,
                          onAction: () => store.addOwn(r),
                        );
                      },
                      child: RecipeCard(match: ranker.match(r)),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ImportSheet extends StatefulWidget {
  const _ImportSheet();

  @override
  State<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends State<_ImportSheet> {
  static const _maxPhotos = 3;
  final _text = TextEditingController();
  final List<Uint8List> _photos = [];
  bool _busy = false;
  ClaudeException? _error;
  String? _hint;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
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
        _photos.add(bytes);
        _hint = null;
      });
    } on UnsupportedImageException {
      if (mounted) setState(() => _hint = s.unsupportedImage);
    } catch (e) {
      debugPrint('Image picker failed: $e');
      if (mounted) setState(() => _hint = s.cameraError);
    }
  }

  Future<void> _import() async {
    final s = context.s;
    if (_text.text.trim().isEmpty && _photos.isEmpty) {
      setState(() => _hint = s.importNeedsInput);
      return;
    }
    if (!await ensurePro(context) || !mounted) return;
    final settings = context.read<SettingsStore>();
    final factory = context.read<AiServiceFactory>();
    final store = context.read<RecipeStore>();
    final pantry = context.read<PantryStore>().items;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _hint = null;
    });
    try {
      final recipe = await factory(settings.effectiveApiKey).importRecipe(
        text: _text.text,
        photos: _photos,
        pantry: pantry,
        languageCode: s.languageCode,
      );
      if (!mounted) return;
      if (recipe == null) {
        setState(() => _hint = s.importFailed);
        return;
      }
      await store.addOwn(recipe);
      if (!mounted) return;
      Navigator.pop(context);
      showSnack(context, s.recipeImported);
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

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.importRecipe, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _text,
              minLines: 4,
              maxLines: 10,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: s.importHint),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (_photos.length < _maxPhotos) ...[
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(s.takePhoto),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(s.fromGallery),
                  ),
                ],
                if (_photos.isNotEmpty)
                  InputChip(
                    avatar: const Icon(Icons.image_outlined, size: 18),
                    label: Text(s.photosAdded(_photos.length)),
                    onDeleted: () => setState(_photos.clear),
                  ),
              ],
            ),
            if (_busy)
              AiProgress(title: s.importing)
            else if (_error != null) ...[
              const SizedBox(height: 12),
              AiErrorCard(error: _error!, onRetry: _import),
            ] else if (_hint != null) ...[
              const SizedBox(height: 8),
              Text(_hint!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _import,
              icon: const Icon(Icons.auto_awesome),
              label: Text(s.importRecipe),
            ),
          ],
        ),
      ),
    );
  }
}
