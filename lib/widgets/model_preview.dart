import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../geometry/furniture_builder.dart';
import '../geometry/glb_writer.dart';
import '../geometry/slot_materials.dart';
import '../models/configuration.dart';

/// Pratinjau 3D + tombol AR untuk konfigurasi yang sedang dipilih.
///
/// Model GLB dibuat ulang setiap kali pilihan berubah dan ditulis ke file
/// yang sama. Model viewer membaca file itu lewat proxy lokalnya, sehingga
/// pratinjau maupun AR (Scene Viewer di Android) selalu memakai ukuran,
/// material, dan warna terbaru dengan skala asli 1:1.
class ModelPreview extends StatefulWidget {
  const ModelPreview({super.key, required this.config});

  final FurnitureConfig config;

  @override
  State<ModelPreview> createState() => _ModelPreviewState();
}

class _ModelPreviewState extends State<ModelPreview> {
  File? _file;
  WebViewController? _controller;
  Timer? _debounce;
  int _version = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/configurator_${widget.config.type.kind.name}.glb',
    );
    await _write(file, widget.config);
    if (mounted) setState(() => _file = file);
  }

  @override
  void didUpdateWidget(ModelPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config == widget.config || _file == null) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _refresh);
  }

  Future<void> _refresh() async {
    final file = _file;
    if (file == null) return;
    await _write(file, widget.config);
    _version++;
    await _controller?.runJavaScript(
      "document.getElementById('mv').src = '/model?v=$_version';",
    );
  }

  static Future<void> _write(File file, FurnitureConfig config) async {
    final bytes = writeGlb(buildFurniture(config).parts, slotMaterials(config));
    // Tulis ke file sementara lalu rename agar viewer tidak membaca file setengah jadi.
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(file.path);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = _file;
    if (file == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final scheme = Theme.of(context).colorScheme;
    return ModelViewer(
      id: 'mv',
      src: Uri.file(file.path).toString(),
      alt: widget.config.type.name,
      ar: true,
      arModes: const ['scene-viewer', 'webxr', 'quick-look'],
      arScale: ArScale.fixed,
      arPlacement: ArPlacement.floor,
      cameraControls: true,
      shadowIntensity: 1,
      shadowSoftness: 0.8,
      exposure: 1.1,
      cameraOrbit: '30deg 70deg auto',
      backgroundColor: scheme.surfaceContainerHighest,
      onWebViewCreated: (controller) => _controller = controller,
      innerModelViewerHtml:
          '<button slot="ar-button" class="ar-btn">Lihat di ruangan (AR)</button>',
      relatedCss: '''
        .ar-btn {
          position: absolute; left: 50%; bottom: 16px; transform: translateX(-50%);
          padding: 12px 20px; border: none; border-radius: 24px;
          background: #5D4037; color: #fff; font: 600 15px sans-serif;
          box-shadow: 0 2px 8px rgba(0,0,0,.25);
        }
      ''',
    );
  }
}
