import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class HydrionPickedProfilePhoto {
  final Uint8List bytes;
  int get byteLength => bytes.length;

  HydrionPickedProfilePhoto(Uint8List source)
      : bytes = Uint8List.fromList(source);
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
    return HydrionPickedProfilePhoto(bytes);
  }
}

class FakeHydrionProfilePhotoPicker implements HydrionProfilePhotoPicker {
  HydrionPickedProfilePhoto? nextPhoto;

  FakeHydrionProfilePhotoPicker([Uint8List? bytes])
      : nextPhoto = bytes == null ? null : HydrionPickedProfilePhoto(bytes);

  @override
  Future<HydrionPickedProfilePhoto?> pickProfilePhoto() async {
    return nextPhoto;
  }
}
