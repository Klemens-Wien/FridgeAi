import 'dart:typed_data';

class UnsupportedImageException implements Exception {
  const UnsupportedImageException();
}

/// Detects the media type from the file's magic bytes. The Claude API accepts
/// JPEG, PNG, GIF and WebP.
String detectImageMediaType(Uint8List bytes) {
  bool starts(List<int> sig, [int offset = 0]) {
    if (bytes.length < offset + sig.length) return false;
    for (var i = 0; i < sig.length; i++) {
      if (bytes[offset + i] != sig[i]) return false;
    }
    return true;
  }

  if (starts([0xFF, 0xD8, 0xFF])) return 'image/jpeg';
  if (starts([0x89, 0x50, 0x4E, 0x47])) return 'image/png';
  if (starts([0x47, 0x49, 0x46, 0x38])) return 'image/gif';
  if (starts([0x52, 0x49, 0x46, 0x46]) && starts([0x57, 0x45, 0x42, 0x50], 8)) {
    return 'image/webp';
  }
  throw const UnsupportedImageException();
}
