import 'dart:io';
import 'dart:math' as math;

import 'package:ar_flutter_plugin_plus/ar_flutter_plugin_plus.dart';
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_plus/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../geometry/glb_file.dart';
import '../state/quote_store.dart';
import '../utils/currency.dart';
import 'catalog_screen.dart';

/// Membuka layar Tata Ruangan (AR). Rute diberi nama agar layar konfigurator
/// bisa kembali ke sini setelah menambah item baru.
Future<void> openRoomAr(BuildContext context) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    settings: const RouteSettings(name: RoomArScreen.routeName),
    builder: (_) => const RoomArScreen(),
  ),
);

/// Menata beberapa furnitur sekaligus di ruangan client.
///
/// Pilih item di baki bawah lalu ketuk lantai. Item yang sudah ditaruh tetap
/// ada saat item berikutnya ditaruh, dan bisa digeser, diputar, atau dihapus.
/// Rotasi lokal terhadap anchor agar sisi depan furnitur (+Z) menghadap
/// posisi kamera saat ditaruh. Setelahnya client bisa memutar sendiri.
Matrix4 faceCameraTransform(Matrix4 anchorWorld, Matrix4? camera) {
  if (camera == null) return Matrix4.identity();
  final p = anchorWorld.getTranslation();
  final c = camera.getTranslation();
  final yaw = math.atan2(c.x - p.x, c.z - p.z);
  final anchorRotationInverse = anchorWorld.getRotation()..transpose();
  final local = anchorRotationInverse.multiplied(Matrix3.rotationY(yaw));
  return Matrix4.compose(
    Vector3.zero(),
    Quaternion.fromRotation(local),
    Vector3.all(1),
  );
}

class RoomArScreen extends StatefulWidget {
  const RoomArScreen({super.key});

  static const routeName = '/tata-ruangan';

  @override
  State<RoomArScreen> createState() => _RoomArScreenState();
}

class _Placed {
  _Placed(this.item, this.anchor, this.node);

  final QuoteItem item;
  final ARPlaneAnchor anchor;
  final ARNode node;
}

class _RoomArScreenState extends State<RoomArScreen> {
  ARSessionManager? _session;
  ARObjectManager? _objects;
  ARAnchorManager? _anchors;

  final _placed = <_Placed>[];

  /// URI model per id item, dibuat sekali per sesi layar ini.
  final _modelUris = <int, String>{};
  QuoteItem? _selectedItem;
  String? _selectedNode;
  int _knownItemCount = 0;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final items = QuoteScope.of(context).items;
    // Item baru (mis. baru ditambah dari katalog) langsung dipilih.
    if (items.length > _knownItemCount && items.isNotEmpty) {
      _selectedItem = items.last;
    } else if (_selectedItem != null && !items.contains(_selectedItem)) {
      _selectedItem = null;
    }
    _knownItemCount = items.length;
  }

  @override
  void dispose() {
    _session?.dispose();
    super.dispose();
  }

  void _onArViewCreated(
    ARSessionManager session,
    ARObjectManager objects,
    ARAnchorManager anchors,
    ARLocationManager location,
  ) {
    _session = session;
    _objects = objects;
    _anchors = anchors;
    session.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
      handlePans: true,
      handleRotation: true,
    );
    // Model kita sudah dalam meter: matikan skala bawaan plugin agar 1:1.
    objects.onInitialize(iosScaleFactor: 1, androidScaleFactor: 1);
    session.onPlaneOrPointTap = _onPlaneTap;
    objects.onNodeTap = (names) {
      if (names.isEmpty) return;
      setState(() => _selectedNode = names.first);
    };
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String> _modelUri(QuoteItem item) async {
    final cached = _modelUris[item.id];
    if (cached != null) return cached;
    // iOS membaca path relatif terhadap folder Documents, Android butuh path absolut.
    final relative = 'ar_items/item_${item.id}.glb';
    final docs = await getApplicationDocumentsDirectory();
    final file = File('${docs.path}/$relative');
    await writeFurnitureGlb(file, item.config);
    final uri = Platform.isIOS ? relative : file.path;
    _modelUris[item.id] = uri;
    return uri;
  }

  Future<void> _onPlaneTap(List<ARHitTestResult> hits) async {
    final item = _selectedItem;
    if (item == null) {
      _toast('Pilih furnitur di bawah dulu, lalu ketuk lantai.');
      return;
    }
    final hit = hits
        .where((h) => h.type == ARHitTestResultType.plane)
        .firstOrNull;
    if (hit == null) {
      _toast('Lantai belum terdeteksi. Gerakkan HP perlahan ke arah lantai.');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final uri = await _modelUri(item);
      final anchor = ARPlaneAnchor(transformation: hit.worldTransform);
      if (await _anchors!.addAnchor(anchor) != true) {
        _toast('Gagal menaruh titik di lantai, coba lagi.');
        return;
      }
      final camera = await _session!.getCameraPose();
      final node = ARNode(
        type: NodeType.fileSystemAppFolderGLB,
        uri: uri,
        transformation: faceCameraTransform(hit.worldTransform, camera),
      );
      if (await _objects!.addNode(node, planeAnchor: anchor) != true) {
        _anchors!.removeAnchor(anchor);
        _toast('Model gagal dimuat.');
        return;
      }
      setState(() => _placed.add(_Placed(item, anchor, node)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _remove(_Placed p) {
    _objects?.removeNode(p.node);
    _anchors?.removeAnchor(p.anchor);
    setState(() {
      _placed.remove(p);
      if (_selectedNode == p.node.name) _selectedNode = null;
    });
  }

  void _removeAll() {
    for (final p in [..._placed]) {
      _remove(p);
    }
  }

  _Placed? get _selectedPlaced =>
      _placed.where((p) => p.node.name == _selectedNode).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final store = QuoteScope.of(context);
    final total = _placed.fold(0, (sum, p) => sum + p.item.price.total);
    final selected = _selectedPlaced;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tata Ruangan (AR)')),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onArViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontal,
            permissionPromptDescription:
                'Izin kamera diperlukan untuk menampilkan furnitur di ruangan.',
            permissionPromptButtonText: 'Beri izin',
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: _Banner(
              text: _placed.isEmpty
                  ? (_selectedItem == null
                        ? 'Pilih furnitur di bawah, lalu ketuk lantai.'
                        : 'Ketuk lantai untuk menaruh ${_selectedItem!.config.type.name}.')
                  : '${_placed.length} item di ruangan · ${formatRupiah(total)}\n'
                        'Geser 1 jari untuk memindah, putar 2 jari untuk memutar.',
            ),
          ),
          if (_busy) const Center(child: CircularProgressIndicator()),
        ],
      ),
      bottomNavigationBar: Material(
        color: theme.colorScheme.surfaceContainer,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    if (selected != null) ...[
                      Expanded(
                        child: Text(
                          'Dipilih: ${selected.item.config.type.name}',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _remove(selected),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Hapus'),
                      ),
                    ] else
                      const Spacer(),
                    IconButton(
                      tooltip: 'Urungkan',
                      onPressed: _placed.isEmpty
                          ? null
                          : () => _remove(_placed.last),
                      icon: const Icon(Icons.undo),
                    ),
                    IconButton(
                      tooltip: 'Hapus semua',
                      onPressed: _placed.isEmpty ? null : _removeAll,
                      icon: const Icon(Icons.layers_clear_outlined),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 112,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8),
                  children: [
                    _TrayCard(
                      icon: Icons.add,
                      title: 'Tambah',
                      subtitle: 'furnitur baru',
                      selected: false,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CatalogScreen(
                            returnTo: RoomArScreen.routeName,
                          ),
                        ),
                      ),
                    ),
                    for (final item in store.items)
                      _TrayCard(
                        icon: item.config.type.icon,
                        title: item.config.type.name,
                        subtitle: item.config.sizeLabel,
                        count: _placed.where((p) => p.item == item).length,
                        selected: item == _selectedItem,
                        onTap: () => setState(() => _selectedItem = item),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _TrayCard extends StatelessWidget {
  const _TrayCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.count = 0,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  /// Berapa kali item ini sudah ditaruh di ruangan.
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SizedBox(
        width: 120,
        child: Card.outlined(
          margin: EdgeInsets.zero,
          color: selected ? scheme.primaryContainer : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Badge.count(
                    count: count,
                    isLabelVisible: count > 0,
                    child: Icon(icon, color: scheme.primary),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
