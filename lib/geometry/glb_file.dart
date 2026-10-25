import 'dart:io';

import '../models/configuration.dart';
import 'furniture_builder.dart';
import 'glb_writer.dart';
import 'slot_materials.dart';

/// Menulis model GLB untuk [config] ke [file].
///
/// Ditulis ke file sementara lalu di-rename agar pembaca (model viewer atau
/// sesi AR) tidak pernah membaca file setengah jadi.
Future<void> writeFurnitureGlb(File file, FurnitureConfig config) async {
  final bytes = writeGlb(buildFurniture(config).parts, slotMaterials(config));
  await file.parent.create(recursive: true);
  final tmp = File('${file.path}.tmp');
  await tmp.writeAsBytes(bytes, flush: true);
  await tmp.rename(file.path);
}
