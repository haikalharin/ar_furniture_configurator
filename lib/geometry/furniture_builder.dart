import 'dart:math' as math;

import '../models/catalog.dart';
import '../models/configuration.dart';

enum PartSlot { body, accent }

/// Satu komponen berbentuk balok, koordinat dalam meter.
///
/// Sumbu mengikuti glTF: X ke kanan, Y ke atas, Z ke arah depan furnitur.
/// Titik (0, 0, 0) berada di tengah lantai, sehingga di AR furnitur
/// langsung berdiri di atas lantai.
class Part {
  const Part(
    this.name,
    this.x0,
    this.x1,
    this.y0,
    this.y1,
    this.z0,
    this.z1, {
    this.slot = PartSlot.body,
  });

  final String name;
  final double x0, x1, y0, y1, z0, z1;
  final PartSlot slot;

  double get sx => x1 - x0;
  double get sy => y1 - y0;
  double get sz => z1 - z0;

  /// Luas lembaran panel: hasil kali dua sisi terpanjang.
  double get sheetArea {
    final dims = [sx, sy, sz]..sort();
    return dims[1] * dims[2];
  }
}

class FurnitureModel {
  const FurnitureModel({required this.parts, this.doors = 0, this.drawers = 0});

  final List<Part> parts;
  final int doors;
  final int drawers;

  Iterable<Part> get bodyParts => parts.where((p) => p.slot == PartSlot.body);
  int get accentCount => parts.where((p) => p.slot == PartSlot.accent).length;

  double get panelAreaM2 => bodyParts.fold(0, (sum, p) => sum + p.sheetArea);
}

const _t = 0.018; // tebal panel 18 mm
const _gap = 0.003; // celah antar pintu

FurnitureModel buildFurniture(FurnitureConfig config) {
  final w = config.widthCm / 100;
  final d = config.depthCm / 100;
  final h = config.heightCm / 100;
  return switch (config.type.kind) {
    FurnitureKind.lemari => _lemari(w, d, h),
    FurnitureKind.bufetTv => _bufet(w, d, h),
    FurnitureKind.rakBuku => _rakBuku(w, d, h),
    FurnitureKind.mejaKerja => _mejaKerja(w, d, h),
    FurnitureKind.mejaMakan => _mejaMakan(w, d, h),
    FurnitureKind.nakas => _nakas(w, d, h),
  };
}

/// Badan kabinet: dua sisi, atas, bawah, dan panel belakang.
/// Bagian depan badan berada di [front]; pintu dipasang di depannya.
List<Part> _carcass(double w, double d, double y0, double y1, double front) {
  final back = -d / 2;
  return [
    Part('Sisi kiri', -w / 2, -w / 2 + _t, y0, y1, back, front),
    Part('Sisi kanan', w / 2 - _t, w / 2, y0, y1, back, front),
    Part('Atas', -w / 2 + _t, w / 2 - _t, y1 - _t, y1, back, front),
    Part('Bawah', -w / 2 + _t, w / 2 - _t, y0, y0 + _t, back, front),
    Part(
      'Belakang',
      -w / 2 + _t,
      w / 2 - _t,
      y0 + _t,
      y1 - _t,
      back,
      back + 0.006,
    ),
  ];
}

List<Part> _legs(
  double w,
  double d,
  double height,
  double size,
  double inset,
  PartSlot slot,
) {
  final parts = <Part>[];
  for (final sx in [-1, 1]) {
    for (final sz in [-1, 1]) {
      final cx = sx * (w / 2 - inset - size / 2);
      final cz = sz * (d / 2 - inset - size / 2);
      parts.add(
        Part(
          'Kaki',
          cx - size / 2,
          cx + size / 2,
          0,
          height,
          cz - size / 2,
          cz + size / 2,
          slot: slot,
        ),
      );
    }
  }
  return parts;
}

Part _verticalHandle(double x, double yCenter, double front) => Part(
  'Handle',
  x - 0.006,
  x + 0.006,
  yCenter - 0.1,
  yCenter + 0.1,
  front,
  front + 0.025,
  slot: PartSlot.accent,
);

Part _horizontalHandle(
  double xCenter,
  double y,
  double front, [
  double length = 0.12,
]) => Part(
  'Handle',
  xCenter - length / 2,
  xCenter + length / 2,
  y - 0.006,
  y + 0.006,
  front,
  front + 0.025,
  slot: PartSlot.accent,
);

FurnitureModel _lemari(double w, double d, double h) {
  const plinth = 0.08;
  final front = d / 2 - _t;
  final parts = <Part>[
    ..._carcass(w, d, plinth, h, front),
    Part(
      'Plint',
      -w / 2 + _t,
      w / 2 - _t,
      0,
      plinth,
      front - 0.03 - _t,
      front - 0.03,
    ),
    // Ambalan atas di dalam (tidak terlihat saat pintu tertutup).
    Part(
      'Ambalan',
      -w / 2 + _t,
      w / 2 - _t,
      h * 0.78,
      h * 0.78 + _t,
      -d / 2 + 0.006,
      front,
    ),
  ];
  final doors = math.max(2, (w / 0.5).round());
  final doorW = w / doors;
  final handleY = math.min(1.05, (plinth + h) / 2);
  for (var i = 0; i < doors; i++) {
    final x0 = -w / 2 + i * doorW + _gap / 2;
    final x1 = x0 + doorW - _gap;
    parts.add(Part('Pintu ${i + 1}', x0, x1, plinth, h, front, d / 2));
    // Handle berpasangan di tengah tiap dua pintu; pintu sisa (ganjil) di kiri.
    final pairedRight = i.isEven && i != doors - 1;
    final handleX = pairedRight ? x1 - 0.04 : x0 + 0.04;
    parts.add(_verticalHandle(handleX, handleY, d / 2));
  }
  return FurnitureModel(parts: parts, doors: doors);
}

FurnitureModel _bufet(double w, double d, double h) {
  const legH = 0.12;
  final front = d / 2 - _t;
  final parts = <Part>[
    ..._carcass(w, d, legH, h, front),
    ..._legs(w, d, legH, 0.03, 0.04, PartSlot.accent),
  ];
  final cols = math.max(2, (w / 0.6).round());
  final colW = w / cols;
  for (var i = 1; i < cols; i++) {
    final x = -w / 2 + i * colW;
    parts.add(
      Part(
        'Sekat',
        x - _t / 2,
        x + _t / 2,
        legH + _t,
        h - _t,
        -d / 2 + 0.006,
        front,
      ),
    );
  }
  // Kolom tengah dibiarkan terbuka untuk perangkat TV bila kolom >= 3.
  final openCol = cols >= 3 ? cols ~/ 2 : -1;
  var doors = 0;
  for (var i = 0; i < cols; i++) {
    final x0 = -w / 2 + i * colW + _gap / 2;
    final x1 = x0 + colW - _gap;
    if (i == openCol) {
      parts.add(
        Part(
          'Ambalan',
          x0,
          x1,
          (legH + h) / 2,
          (legH + h) / 2 + _t,
          -d / 2 + 0.006,
          front,
        ),
      );
      continue;
    }
    doors++;
    parts.add(Part('Pintu', x0, x1, legH, h, front, d / 2));
    parts.add(_horizontalHandle((x0 + x1) / 2, h - 0.05, d / 2));
  }
  return FurnitureModel(parts: parts, doors: doors);
}

FurnitureModel _rakBuku(double w, double d, double h) {
  const plinth = 0.05;
  final front = d / 2;
  final parts = <Part>[
    ..._carcass(w, d, plinth, h, front),
    Part(
      'Plint',
      -w / 2 + _t,
      w / 2 - _t,
      0,
      plinth,
      front - 0.02 - _t,
      front - 0.02,
    ),
  ];
  final innerBottom = plinth + _t;
  final innerTop = h - _t;
  final rows = math.max(2, ((innerTop - innerBottom) / 0.35).round());
  final rowH = (innerTop - innerBottom) / rows;
  for (var i = 1; i < rows; i++) {
    final y = innerBottom + i * rowH;
    parts.add(
      Part(
        'Ambalan',
        -w / 2 + _t,
        w / 2 - _t,
        y - _t / 2,
        y + _t / 2,
        -d / 2 + 0.006,
        front,
      ),
    );
  }
  final cols = math.max(1, (w / 0.8).ceil());
  for (var i = 1; i < cols; i++) {
    final x = -w / 2 + i * w / cols;
    parts.add(
      Part(
        'Sekat',
        x - _t / 2,
        x + _t / 2,
        innerBottom,
        innerTop,
        -d / 2 + 0.006,
        front,
      ),
    );
  }
  return FurnitureModel(parts: parts);
}

FurnitureModel _mejaKerja(double w, double d, double h) {
  const top = 0.025;
  const leg = 0.04;
  final parts = <Part>[
    Part('Daun meja', -w / 2, w / 2, h - top, h, -d / 2, d / 2),
    ..._legs(w, d, h - top, leg, 0.03, PartSlot.accent),
    Part(
      'Panel belakang',
      -w / 2 + 0.03 + leg,
      w / 2 - 0.03 - leg,
      h - top - 0.35,
      h - top,
      -d / 2 + 0.05,
      -d / 2 + 0.05 + _t,
    ),
  ];
  return FurnitureModel(parts: parts);
}

FurnitureModel _mejaMakan(double w, double d, double h) {
  const top = 0.03;
  const leg = 0.06;
  const inset = 0.06;
  const apron = 0.08;
  final ay1 = h - top;
  final ay0 = ay1 - apron;
  final ix = w / 2 - inset - leg;
  final iz = d / 2 - inset - leg;
  final parts = <Part>[
    Part('Daun meja', -w / 2, w / 2, h - top, h, -d / 2, d / 2),
    ..._legs(w, d, h - top, leg, inset, PartSlot.body),
    Part('Rangka depan', -ix, ix, ay0, ay1, iz + leg / 2 - _t, iz + leg / 2),
    Part(
      'Rangka belakang',
      -ix,
      ix,
      ay0,
      ay1,
      -iz - leg / 2,
      -iz - leg / 2 + _t,
    ),
    Part('Rangka kiri', -ix - leg / 2, -ix - leg / 2 + _t, ay0, ay1, -iz, iz),
    Part('Rangka kanan', ix + leg / 2 - _t, ix + leg / 2, ay0, ay1, -iz, iz),
  ];
  return FurnitureModel(parts: parts);
}

FurnitureModel _nakas(double w, double d, double h) {
  const legH = 0.1;
  final front = d / 2 - _t;
  final parts = <Part>[
    ..._carcass(w, d, legH, h, front),
    ..._legs(w, d, legH, 0.025, 0.025, PartSlot.accent),
  ];
  const drawers = 2;
  final drawerH = (h - legH) / drawers;
  for (var i = 0; i < drawers; i++) {
    final y0 = legH + i * drawerH + _gap / 2;
    final y1 = y0 + drawerH - _gap;
    parts.add(Part('Laci ${i + 1}', -w / 2, w / 2, y0, y1, front, d / 2));
    parts.add(_horizontalHandle(0, (y0 + y1) / 2, d / 2, 0.1));
  }
  return FurnitureModel(parts: parts, drawers: drawers);
}
