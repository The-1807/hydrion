import 'package:flutter/material.dart';

class HydrionLogo extends StatelessWidget {
  final double size;
  final Key? imageKey;
  final String semanticLabel;

  const HydrionLogo({
    super.key,
    this.size = 40,
    this.imageKey,
    this.semanticLabel = 'Hydrion logo',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: Image.asset(
        'assets/icons/icon1807.png',
        key: imageKey,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.water_drop,
            size: size,
            color: Theme.of(context).colorScheme.primary,
          );
        },
      ),
    );
  }
}
