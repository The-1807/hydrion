import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

enum ProfilePhotoValidationFailure {
  legacyBoundary,
  byteLimit,
  encoding,
  image,
  dimensions
}

final class InvalidProfilePhoto implements Exception {
  final ProfilePhotoValidationFailure reason;
  const InvalidProfilePhoto(this.reason);
  @override
  String toString() => 'InvalidProfilePhoto(${reason.name})';
}

/// Construction is private so storage cannot accept unvalidated image bytes.
final class ValidatedProfilePhoto {
  static const maximumBytes = 1200000;
  static const maximumLegacyCharacters = 1600000;
  static const maximumDimension = 720;
  final Uint8List _bytes;
  final int width;
  final int height;
  ValidatedProfilePhoto._(this._bytes, this.width, this.height);

  Uint8List get bytes => Uint8List.fromList(_bytes);

  static Future<ValidatedProfilePhoto> fromLegacy(String source) async {
    if (source.length > maximumLegacyCharacters) {
      throw const InvalidProfilePhoto(
          ProfilePhotoValidationFailure.legacyBoundary);
    }
    final Uint8List bytes;
    try {
      bytes = base64Decode(source);
    } on FormatException {
      throw const InvalidProfilePhoto(ProfilePhotoValidationFailure.encoding);
    }
    return fromBytes(bytes);
  }

  static Future<ValidatedProfilePhoto> fromBytes(Uint8List source) async {
    if (source.length > maximumBytes) {
      throw const InvalidProfilePhoto(ProfilePhotoValidationFailure.byteLimit);
    }
    // Copy before asynchronous decoding so callers cannot change validated data.
    final bytes = Uint8List.fromList(source);
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (descriptor.width > maximumDimension ||
          descriptor.height > maximumDimension ||
          descriptor.width < 1 ||
          descriptor.height < 1) {
        throw const InvalidProfilePhoto(
            ProfilePhotoValidationFailure.dimensions);
      }
      codec = await descriptor.instantiateCodec();
      // Decode every frame: accepting just metadata/first-frame success could
      // leave malformed or oversized animated content in protected storage.
      for (var index = 0; index < codec.frameCount; index++) {
        image = (await codec.getNextFrame()).image;
        if (image.width > maximumDimension || image.height > maximumDimension) {
          throw const InvalidProfilePhoto(
              ProfilePhotoValidationFailure.dimensions);
        }
        image.dispose();
        image = null;
      }
      return ValidatedProfilePhoto._(
          bytes, descriptor.width, descriptor.height);
    } on InvalidProfilePhoto {
      rethrow;
    } catch (_) {
      throw const InvalidProfilePhoto(ProfilePhotoValidationFailure.image);
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
  }

  @override
  String toString() => 'ValidatedProfilePhoto';
}
