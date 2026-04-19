import 'dart:typed_data';

class ImageUploadData {
  final Uint8List bytes;
  final String fileName;
  final String? contentType;

  const ImageUploadData({
    required this.bytes,
    required this.fileName,
    this.contentType,
  });
}
