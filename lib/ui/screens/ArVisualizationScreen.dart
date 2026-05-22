import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../../utils/i18n_resolver.dart';
import 'package:provider/provider.dart';

/// ArVisualizationScreen — basic AR overlay of hydration wave.
/// Ensure ARCore/ARKit availability on device; otherwise show message.
class ArVisualizationScreen extends StatefulWidget {
  const ArVisualizationScreen({super.key});

  @override
  State<ArVisualizationScreen> createState() => _ArVisualizationScreenState();
}

class _ArVisualizationScreenState extends State<ArVisualizationScreen> {
  ARSessionManager? _sessionManager;
  ARObjectManager? _objectManager;
  bool _ready = false;
  String? _error;

  Future<void> _onARViewCreated(ARSessionManager s, ARObjectManager o, ARAnchorManager a, ARLocationManager l) async {
    _sessionManager = s;
    _objectManager = o;
    try {
      await _sessionManager?.onInitialize(
        showFeaturePoints: false,
        showPlanes: true,
        showWorldOrigin: false,
        handleTaps: false,
      );
      final ok = await _objectManager?.onInitialize() ?? false;
      if (!ok) throw Exception('Object manager init failed');

      // Add hydration wave model (GLB/USDZ in assets)
      await _objectManager?.addNode(
        ARNode(
          type: NodeType.localGLTF2,
          uri: 'assets/ar/wave_effect.glb',
          scale: Vector3(0.5, 0.5, 0.5),
          position: Vector3(0.0, 0.0, -1.0),
        ),
      );

      setState(() => _ready = true);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _sessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.read<I18nResolver>();
    final dir = Directionality.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.getText('ar_title', 'AR Hydration View'), textDirection: dir),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          if (_error != null)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  i18n.getText('ar_error', 'AR not available: $_error'),
                  textDirection: dir,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          if (!_ready && _error == null)
            const Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
