import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../l10n/strings.dart';
import '../../services/claude_client.dart';
import '../../services/image_utils.dart';
import '../../state/recipe_store.dart';
import '../../state/settings_store.dart';
import '../widgets/common.dart';
import 'review_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _picker = ImagePicker();
  final List<Uint8List> _photos = [];
  bool _busy = false;
  bool _receipt = false;
  ClaudeException? _error;

  int get _remaining => AppConfig.maxPhotos - _photos.length;

  Future<void> _pick(ImageSource source) async {
    final s = context.s;
    if (_remaining <= 0) {
      showSnack(context, s.maxPhotosReached(AppConfig.maxPhotos));
      return;
    }
    try {
      const dim = AppConfig.maxImageDimension;
      final List<XFile> files;
      if (source == ImageSource.camera) {
        final f = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: dim,
          maxHeight: dim,
          imageQuality: 85,
        );
        files = f == null ? [] : [f];
      } else {
        files = await _picker.pickMultiImage(
          maxWidth: dim,
          maxHeight: dim,
          imageQuality: 85,
          limit: _remaining > 1 ? _remaining : null,
        );
      }
      final added = <Uint8List>[];
      for (final f in files.take(_remaining)) {
        final bytes = await f.readAsBytes();
        try {
          detectImageMediaType(bytes);
          added.add(bytes);
        } on UnsupportedImageException {
          if (mounted) showSnack(context, s.unsupportedImage);
        }
      }
      if (files.length > _remaining && mounted) {
        showSnack(context, s.maxPhotosReached(AppConfig.maxPhotos));
      }
      setState(() {
        _photos.addAll(added);
        _error = null;
      });
    } catch (e) {
      debugPrint('Image picker failed: $e');
      if (mounted) showSnack(context, s.cameraError);
    }
  }

  Future<void> _analyze() async {
    final settings = context.read<SettingsStore>();
    final factory = context.read<AiServiceFactory>();
    final lang = context.s.languageCode;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final detected = await factory(settings.effectiveApiKey)
          .detectIngredients(_photos, languageCode: lang, receipt: _receipt);
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ReviewScreen(initial: detected)),
      );
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
    final hasKey = context.select<SettingsStore, bool>((s) => s.hasApiKey);

    return Scaffold(
      appBar: AppBar(title: Text(s.scanTitle)),
      body: _busy
          ? Center(child: AiProgress(title: s.analyzing, subtitle: s.analyzingHint))
          : Column(
              children: [
                if (!hasKey) const MissingApiKeyBanner(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<bool>(
                          segments: [
                            ButtonSegment(
                              value: false,
                              icon: const Icon(Icons.kitchen_outlined),
                              label: Text(s.scanModeFridge),
                            ),
                            ButtonSegment(
                              value: true,
                              icon: const Icon(Icons.receipt_long_outlined),
                              label: Text(s.scanModeReceipt),
                            ),
                          ],
                          selected: {_receipt},
                          onSelectionChanged: (v) =>
                              setState(() => _receipt = v.first),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _receipt ? s.receiptHint : s.scanHint,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: () => _pick(ImageSource.camera),
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: Text(s.takePhoto),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pick(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: Text(s.fromGallery),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        s.photosCount(_photos.length, AppConfig.maxPhotos),
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _photos.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemBuilder: (_, i) => _Thumb(
                          bytes: _photos[i],
                          onRemove: () => setState(() => _photos.removeAt(i)),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        AiErrorCard(error: _error!, onRetry: _analyze),
                      ],
                    ],
                  ),
                ),
                SafeArea(
                  minimum: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _photos.isEmpty ? null : _analyze,
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(_receipt ? s.analyzeReceipt : s.analyze),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.bytes, required this.onRemove});
  final Uint8List bytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(bytes, fit: BoxFit.cover, cacheWidth: 300),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton.filledTonal(
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            onPressed: onRemove,
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }
}
