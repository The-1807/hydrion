import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class HydrionStartupShark extends StatelessWidget {
  static const sharkAssetPath = 'assets/buffer/Shark.json';
  static const sharkSourceAssetPath = 'assets/buffer/Shark.lottie';
  static const sharkAnimationId = '12345';
  static const sharkAnimationName = 'animals 3';

  final double size;
  final bool animate;
  final VoidCallback? onLoaded;

  const HydrionStartupShark({
    super.key,
    this.size = 180,
    this.animate = true,
    this.onLoaded,
  });

  static Future<LottieComposition?> decodeSharkDotLottie(List<int> bytes) {
    return LottieComposition.decodeZip(
      Uint8List.fromList(bytes),
      filePicker: (files) {
        for (final file in files) {
          if (file.name == 'animations/$sharkAnimationId.json') {
            return file;
          }
        }
        for (final file in files) {
          if (file.name.startsWith('animations/') &&
              file.name.endsWith('.json')) {
            return file;
          }
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Hydrion shark startup animation',
      image: true,
      child: RepaintBoundary(
        child: SizedBox.square(
          key: const Key('startup-shark-loader'),
          dimension: size,
          child: Lottie.asset(
            sharkAssetPath,
            key: const Key('hydrion-shark-lottie-loader'),
            fit: BoxFit.contain,
            animate: animate,
            repeat: animate,
            onLoaded: (_) => onLoaded?.call(),
          ),
        ),
      ),
    );
  }
}
