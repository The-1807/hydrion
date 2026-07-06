import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class HydrionPickedProfilePhoto {
  final String base64Data;
  final int byteLength;

  const HydrionPickedProfilePhoto({
    required this.base64Data,
    required this.byteLength,
  });
}

abstract class HydrionProfilePhotoPicker {
  Future<HydrionPickedProfilePhoto?> pickProfilePhoto();
}

class ImagePickerHydrionProfilePhotoPicker
    implements HydrionProfilePhotoPicker {
  final ImagePicker _picker;

  ImagePickerHydrionProfilePhotoPicker({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  @override
  Future<HydrionPickedProfilePhoto?> pickProfilePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 720,
      maxHeight: 720,
      imageQuality: 82,
    );
    if (picked == null) {
      return null;
    }
    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      return null;
    }
    return HydrionPickedProfilePhoto(
      base64Data: base64Encode(bytes),
      byteLength: bytes.length,
    );
  }
}

class FakeHydrionProfilePhotoPicker implements HydrionProfilePhotoPicker {
  HydrionPickedProfilePhoto? nextPhoto;

  FakeHydrionProfilePhotoPicker([Uint8List? bytes])
      : nextPhoto = bytes == null
            ? null
            : HydrionPickedProfilePhoto(
                base64Data: base64Encode(bytes),
                byteLength: bytes.length,
              );

  @override
  Future<HydrionPickedProfilePhoto?> pickProfilePhoto() async {
    return nextPhoto;
  }
}
