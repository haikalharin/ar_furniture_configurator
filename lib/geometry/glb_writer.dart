import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'furniture_builder.dart';

/// Material PBR sederhana untuk satu [PartSlot].
class GlbMaterial {
  const GlbMaterial({
    required this.name,
    required this.rgbHex,
    this.metallic = 0,
    this.roughness = 0.5,
  });

  final String name;
  final int rgbHex;
  final double metallic;
  final double roughness;

  /// glTF menyimpan baseColorFactor dalam ruang warna linear.
  List<double> get linearColor => [
    for (final shift in [16, 8, 0])
      _srgbToLinear(((rgbHex >> shift) & 0xFF) / 255),
    1,
  ];

  static double _srgbToLinear(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

// Enam sisi balok: normal, lalu empat sudut (indeks bit: x, y, z).
const _faces = <(List<double>, List<int>)>[
  ([1, 0, 0], [0x1, 0x3, 0x7, 0x5]),
  ([-1, 0, 0], [0x0, 0x4, 0x6, 0x2]),
  ([0, 1, 0], [0x2, 0x6, 0x7, 0x3]),
  ([0, -1, 0], [0x0, 0x1, 0x5, 0x4]),
  ([0, 0, 1], [0x4, 0x5, 0x7, 0x6]),
  ([0, 0, -1], [0x0, 0x2, 0x3, 0x1]),
];

/// Menyusun file GLB (glTF 2.0 biner) dari kumpulan balok.
/// Setiap slot menjadi satu primitive dengan materialnya sendiri.
Uint8List writeGlb(List<Part> parts, Map<PartSlot, GlbMaterial> materials) {
  final bin = BytesBuilder();
  final bufferViews = <Map<String, Object>>[];
  final accessors = <Map<String, Object>>[];
  final primitives = <Map<String, Object>>[];
  final gltfMaterials = <Map<String, Object>>[];

  int addView(Uint8List bytes, int target) {
    final offset = bin.length;
    bin.add(bytes);
    while (bin.length % 4 != 0) {
      bin.addByte(0);
    }
    bufferViews.add({
      'buffer': 0,
      'byteOffset': offset,
      'byteLength': bytes.length,
      'target': target,
    });
    return bufferViews.length - 1;
  }

  for (final slot in PartSlot.values) {
    final slotParts = parts.where((p) => p.slot == slot).toList();
    final material = materials[slot];
    if (slotParts.isEmpty || material == null) continue;

    final positions = Float32List(slotParts.length * 24 * 3);
    final normals = Float32List(slotParts.length * 24 * 3);
    final indices = Uint32List(slotParts.length * 36);
    final min = [double.infinity, double.infinity, double.infinity];
    final max = [-double.infinity, -double.infinity, -double.infinity];
    var v = 0;
    var i = 0;
    for (final p in slotParts) {
      for (final (normal, corners) in _faces) {
        final base = v;
        for (final c in corners) {
          final xyz = [
            c & 1 == 0 ? p.x0 : p.x1,
            c & 2 == 0 ? p.y0 : p.y1,
            c & 4 == 0 ? p.z0 : p.z1,
          ];
          for (var k = 0; k < 3; k++) {
            positions[v * 3 + k] = xyz[k];
            normals[v * 3 + k] = normal[k];
            min[k] = math.min(min[k], xyz[k]);
            max[k] = math.max(max[k], xyz[k]);
          }
          v++;
        }
        for (final o in [0, 1, 2, 0, 2, 3]) {
          indices[i++] = base + o;
        }
      }
    }

    final posView = addView(positions.buffer.asUint8List(), 34962);
    final normView = addView(normals.buffer.asUint8List(), 34962);
    final idxView = addView(indices.buffer.asUint8List(), 34963);
    accessors
      ..add({
        'bufferView': posView,
        'componentType': 5126,
        'count': v,
        'type': 'VEC3',
        'min': min,
        'max': max,
      })
      ..add({
        'bufferView': normView,
        'componentType': 5126,
        'count': v,
        'type': 'VEC3',
      })
      ..add({
        'bufferView': idxView,
        'componentType': 5125,
        'count': i,
        'type': 'SCALAR',
      });
    gltfMaterials.add({
      'name': material.name,
      'pbrMetallicRoughness': {
        'baseColorFactor': material.linearColor,
        'metallicFactor': material.metallic,
        'roughnessFactor': material.roughness,
      },
    });
    final a = accessors.length;
    primitives.add({
      'attributes': {'POSITION': a - 3, 'NORMAL': a - 2},
      'indices': a - 1,
      'material': gltfMaterials.length - 1,
    });
  }

  final binBytes = bin.takeBytes();
  final json = {
    'asset': {'version': '2.0', 'generator': 'ar_furniture_configurator'},
    'scene': 0,
    'scenes': [
      {
        'nodes': [0],
      },
    ],
    'nodes': [
      {'mesh': 0, 'name': 'Furniture'},
    ],
    'meshes': [
      {'primitives': primitives},
    ],
    'materials': gltfMaterials,
    'accessors': accessors,
    'bufferViews': bufferViews,
    'buffers': [
      {'byteLength': binBytes.length},
    ],
  };

  final jsonBytes = utf8.encode(jsonEncode(json));
  final jsonPadded = jsonBytes.length + (4 - jsonBytes.length % 4) % 4;
  final total = 12 + 8 + jsonPadded + 8 + binBytes.length;

  final out = ByteData(total);
  var o = 0;
  void u32(int value) {
    out.setUint32(o, value, Endian.little);
    o += 4;
  }

  u32(0x46546C67); // 'glTF'
  u32(2);
  u32(total);
  u32(jsonPadded);
  u32(0x4E4F534A); // 'JSON'
  for (var k = 0; k < jsonPadded; k++) {
    out.setUint8(o++, k < jsonBytes.length ? jsonBytes[k] : 0x20);
  }
  u32(binBytes.length);
  u32(0x004E4942); // 'BIN'
  for (final b in binBytes) {
    out.setUint8(o++, b);
  }
  return out.buffer.asUint8List();
}
