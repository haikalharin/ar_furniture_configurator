import 'dart:math' as math;

import '../models/catalog.dart';
import '../models/configuration.dart';

enum PartSlot {
  /// Panel utama, mengikuti material dan warna pilihan.
  body,

  /// Handle dan kaki besi, mengikuti pilihan aksen.
  accent,
  glass,
  mirror,
  fabric,

  /// Top table solid surface / batu.
  stone,

  /// Strip lampu LED.
  light,
}

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
  const FurnitureModel({
    required this.parts,
    this.doors = 0,
    this.drawers = 0,
    this.slidingDoors = 0,
  });

  final List<Part> parts;

  /// Pintu ayun (pakai engsel).
  final int doors;
  final int drawers;

  /// Pintu geser (pakai set rel).
  final int slidingDoors;

  int get accentCount => parts.where((p) => p.slot == PartSlot.accent).length;

  /// Total panjang (m) komponen pada satu slot, mis. strip LED.
  double lengthOf(PartSlot slot) => parts
      .where((p) => p.slot == slot)
      .fold(0, (sum, p) => sum + math.max(p.sx, math.max(p.sy, p.sz)));

  /// Total luas lembaran (m²) untuk satu slot.
  double areaOf(PartSlot slot) =>
      parts.where((p) => p.slot == slot).fold(0, (sum, p) => sum + p.sheetArea);
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
    FurnitureKind.tempatTidur => _tempatTidur(w, d, h),
    FurnitureKind.mejaRias => _mejaRias(w, d, h),
    FurnitureKind.mejaKopi => _mejaKopi(w, d, h),
    FurnitureKind.backdropTv => _backdropTv(w, d, h),
    FurnitureKind.lemariPajangan => _lemariPajangan(w, d, h),
    FurnitureKind.rakSepatu => _rakSepatu(w, d, h),
    FurnitureKind.kitchenBawah => _kitchenBawah(w, d, h),
    FurnitureKind.kabinetGantung => _kabinetGantung(w, d, h),
    FurnitureKind.kursiMakan => _kursiMakan(w, d, h),
    FurnitureKind.bangku => _bangku(w, d, h),
    FurnitureKind.mejaBar => _mejaBar(w, d, h),
    FurnitureKind.mejaResepsionis => _mejaResepsionis(w, d, h),
    FurnitureKind.kitchenL => _kitchenL(w, d, h),
    FurnitureKind.kitchenLengkap => _kitchenLengkap(w, d, h),
    FurnitureKind.kitchenIsland => _kitchenIsland(w, d, h),
    FurnitureKind.lemariSliding => _lemariSliding(w, d, h),
    FurnitureKind.lemariDisplay => _lemariDisplay(w, d, h),
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

/// Deretan pintu ayun selebar [x0]..[x1]. Handle horizontal di dekat
/// [handleAtTop] (atas) atau bawah pintu. Mengembalikan pintu + handle.
List<Part> _doorRow({
  required double x0,
  required double x1,
  required double y0,
  required double y1,
  required double front,
  required double face,
  required int count,
  bool handleAtTop = true,
  PartSlot doorSlot = PartSlot.body,
}) {
  final parts = <Part>[];
  final doorW = (x1 - x0) / count;
  for (var i = 0; i < count; i++) {
    final dx0 = x0 + i * doorW + _gap / 2;
    final dx1 = dx0 + doorW - _gap;
    parts
      ..add(
        Part(
          'Pintu ${i + 1}',
          dx0,
          dx1,
          y0 + _gap / 2,
          y1 - _gap / 2,
          front,
          face,
          slot: doorSlot,
        ),
      )
      ..add(
        _horizontalHandle(
          (dx0 + dx1) / 2,
          handleAtTop ? y1 - 0.05 : y0 + 0.05,
          face,
          math.min(0.12, doorW * 0.5),
        ),
      );
  }
  return parts;
}

/// Ambalan rata di dalam badan kabinet, dibagi sama rata.
List<Part> _shelves(
  double w,
  double d,
  double innerBottom,
  double innerTop,
  double front,
  int rows,
) {
  final rowH = (innerTop - innerBottom) / rows;
  return [
    for (var i = 1; i < rows; i++)
      Part(
        'Ambalan',
        -w / 2 + _t,
        w / 2 - _t,
        innerBottom + i * rowH - _t / 2,
        innerBottom + i * rowH + _t / 2,
        -d / 2 + 0.006,
        front,
      ),
  ];
}

FurnitureModel _tempatTidur(double w, double d, double h) {
  // d adalah panjang kasur; headboard menempel di dinding (sisi belakang).
  const frameH = 0.3;
  const board = 0.05;
  final back = -d / 2;
  final parts = <Part>[
    Part('Headboard', -w / 2, w / 2, 0, h, back, back + board),
    Part(
      'Jok headboard',
      -w / 2 + 0.05,
      w / 2 - 0.05,
      frameH + 0.15,
      h - 0.05,
      back + board,
      back + board + 0.05,
      slot: PartSlot.fabric,
    ),
    Part('Rangka kiri', -w / 2, -w / 2 + 0.025, 0, frameH, back + board, d / 2),
    Part('Rangka kanan', w / 2 - 0.025, w / 2, 0, frameH, back + board, d / 2),
    Part(
      'Rangka kaki',
      -w / 2 + 0.025,
      w / 2 - 0.025,
      0,
      frameH,
      d / 2 - 0.025,
      d / 2,
    ),
    Part(
      'Alas kasur',
      -w / 2 + 0.025,
      w / 2 - 0.025,
      frameH - 0.06,
      frameH - 0.042,
      back + board,
      d / 2 - 0.025,
    ),
  ];
  return FurnitureModel(parts: parts);
}

FurnitureModel _mejaRias(double w, double d, double h) {
  const deskH = 0.75;
  const top = 0.025;
  final mirrorW = math.min(0.6, w * 0.6);
  final back = -d / 2;
  final parts = <Part>[
    Part('Daun meja', -w / 2, w / 2, deskH - top, deskH, back, d / 2),
    Part('Sisi kiri', -w / 2, -w / 2 + _t, 0, deskH - top, back, d / 2 - 0.02),
    Part('Sisi kanan', w / 2 - _t, w / 2, 0, deskH - top, back, d / 2 - 0.02),
    Part(
      'Laci',
      -w / 2 + _t + _gap,
      w / 2 - _t - _gap,
      deskH - top - 0.14,
      deskH - top - _gap,
      d / 2 - 0.02 - _t,
      d / 2 - 0.02,
    ),
    _horizontalHandle(0, deskH - top - 0.07, d / 2 - 0.02),
    Part(
      'Bingkai cermin',
      -mirrorW / 2,
      mirrorW / 2,
      deskH,
      h,
      back,
      back + 0.02,
    ),
    Part(
      'Cermin',
      -mirrorW / 2 + 0.03,
      mirrorW / 2 - 0.03,
      deskH + 0.03,
      h - 0.03,
      back + 0.02,
      back + 0.025,
      slot: PartSlot.mirror,
    ),
  ];
  return FurnitureModel(parts: parts, drawers: 1);
}

FurnitureModel _mejaKopi(double w, double d, double h) {
  const top = 0.03;
  const leg = 0.03;
  const inset = 0.04;
  final parts = <Part>[
    Part('Daun meja', -w / 2, w / 2, h - top, h, -d / 2, d / 2),
    ..._legs(w, d, h - top, leg, inset, PartSlot.accent),
    Part(
      'Ambalan bawah',
      -w / 2 + inset,
      w / 2 - inset,
      0.1,
      0.1 + _t,
      -d / 2 + inset,
      d / 2 - inset,
    ),
  ];
  return FurnitureModel(parts: parts);
}

FurnitureModel _backdropTv(double w, double d, double h) {
  // d adalah kedalaman kabinet gantung di bawah TV.
  final back = -d / 2;
  final panelFront = back + _t;
  const cabY0 = 0.3;
  const cabH = 0.35;
  final cabW = w * 0.8;
  final front = d / 2 - _t;
  final parts = <Part>[
    Part('Panel dinding', -w / 2, w / 2, 0, h, back, panelFront),
    // Kabinet gantung (tanpa panel belakang, menempel ke panel dinding).
    Part(
      'Sisi kiri',
      -cabW / 2,
      -cabW / 2 + _t,
      cabY0,
      cabY0 + cabH,
      panelFront,
      front,
    ),
    Part(
      'Sisi kanan',
      cabW / 2 - _t,
      cabW / 2,
      cabY0,
      cabY0 + cabH,
      panelFront,
      front,
    ),
    Part(
      'Atas',
      -cabW / 2 + _t,
      cabW / 2 - _t,
      cabY0 + cabH - _t,
      cabY0 + cabH,
      panelFront,
      front,
    ),
    Part(
      'Bawah',
      -cabW / 2 + _t,
      cabW / 2 - _t,
      cabY0,
      cabY0 + _t,
      panelFront,
      front,
    ),
  ];
  final doors = math.max(2, (cabW / 0.6).round());
  parts.addAll(
    _doorRow(
      x0: -cabW / 2,
      x1: cabW / 2,
      y0: cabY0,
      y1: cabY0 + cabH,
      front: front,
      face: d / 2,
      count: doors,
    ),
  );
  // Lis vertikal dekoratif di atas kabinet.
  const slatW = 0.03;
  const pitch = 0.12;
  final slats = ((w - 0.2) / pitch).floor();
  final startX = -(slats - 1) * pitch / 2;
  for (var i = 0; i < slats; i++) {
    final x = startX + i * pitch;
    parts.add(
      Part(
        'Lis',
        x - slatW / 2,
        x + slatW / 2,
        cabY0 + cabH + 0.4,
        h - 0.1,
        panelFront,
        panelFront + 0.015,
      ),
    );
  }
  return FurnitureModel(parts: parts, doors: doors);
}

FurnitureModel _lemariPajangan(double w, double d, double h) {
  const plinth = 0.08;
  const glass = 0.005;
  final front = d / 2 - glass - 0.002;
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
    ..._shelves(
      w,
      d,
      plinth + _t,
      h - _t,
      front,
      math.max(3, ((h - plinth) / 0.35).round()),
    ),
  ];
  final doors = math.max(1, (w / 0.5).round());
  final doorW = w / doors;
  final handleY = math.min(1.0, (plinth + h) / 2);
  for (var i = 0; i < doors; i++) {
    final x0 = -w / 2 + i * doorW + _gap / 2;
    final x1 = x0 + doorW - _gap;
    parts.add(
      Part(
        'Pintu kaca ${i + 1}',
        x0,
        x1,
        plinth,
        h,
        d / 2 - glass,
        d / 2,
        slot: PartSlot.glass,
      ),
    );
    parts.add(
      _verticalHandle(i.isEven ? x1 - 0.03 : x0 + 0.03, handleY, d / 2),
    );
  }
  return FurnitureModel(parts: parts, doors: doors);
}

FurnitureModel _rakSepatu(double w, double d, double h) {
  const plinth = 0.05;
  final front = d / 2 - _t;
  final doors = math.max(1, (w / 0.45).round());
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
    ..._shelves(
      w,
      d,
      plinth + _t,
      h - _t,
      front,
      math.max(2, ((h - plinth) / 0.18).floor()),
    ),
    ..._doorRow(
      x0: -w / 2,
      x1: w / 2,
      y0: plinth,
      y1: h,
      front: front,
      face: d / 2,
      count: doors,
    ),
  ];
  return FurnitureModel(parts: parts, doors: doors);
}

FurnitureModel _kitchenBawah(double w, double d, double h) =>
    _lowerRun(w, d, h, drawerColumn: 0);

/// Tinggi bawah kabinet gantung dapur dari lantai (meter), standar 145 cm.
const kitchenWallMountM = 1.45;

FurnitureModel _kabinetGantung(double w, double d, double h) {
  const y0 = kitchenWallMountM;
  final front = d / 2 - _t;
  final doors = math.max(2, (w / 0.5).round());
  final parts = <Part>[
    ..._carcass(w, d, y0, y0 + h, front),
    ..._shelves(w, d, y0 + _t, y0 + h - _t, front, 2),
    ..._doorRow(
      x0: -w / 2,
      x1: w / 2,
      y0: y0,
      y1: y0 + h,
      front: front,
      face: d / 2,
      count: doors,
      handleAtTop: false,
    ),
  ];
  return FurnitureModel(parts: parts, doors: doors);
}

FurnitureModel _kursiMakan(double w, double d, double h) {
  const seatY = 0.45;
  const seatT = 0.02;
  const cushion = 0.04;
  const leg = 0.035;
  final back = -d / 2;
  final parts = <Part>[
    for (final x in [-w / 2, w / 2 - leg]) ...[
      Part('Kaki depan', x, x + leg, 0, seatY - seatT, d / 2 - leg, d / 2),
      Part('Kaki belakang', x, x + leg, 0, h, back, back + leg),
    ],
    Part('Dudukan', -w / 2, w / 2, seatY - seatT, seatY, back + leg, d / 2),
    Part(
      'Jok dudukan',
      -w / 2 + 0.01,
      w / 2 - 0.01,
      seatY,
      seatY + cushion,
      back + leg + 0.01,
      d / 2 - 0.01,
      slot: PartSlot.fabric,
    ),
    Part(
      'Sandaran',
      -w / 2 + leg,
      w / 2 - leg,
      h - 0.2,
      h - 0.03,
      back + 0.005,
      back + 0.005 + seatT,
    ),
    Part(
      'Palang',
      -w / 2 + leg,
      w / 2 - leg,
      0.15,
      0.18,
      back + 0.005,
      back + 0.025,
    ),
  ];
  return FurnitureModel(parts: parts);
}

FurnitureModel _bangku(double w, double d, double h) {
  const cushion = 0.04;
  const seatT = 0.025;
  final seatY = h - cushion;
  final parts = <Part>[
    Part('Dudukan', -w / 2, w / 2, seatY - seatT, seatY, -d / 2, d / 2),
    Part(
      'Jok',
      -w / 2 + 0.01,
      w / 2 - 0.01,
      seatY,
      h,
      -d / 2 + 0.01,
      d / 2 - 0.01,
      slot: PartSlot.fabric,
    ),
    ..._legs(w, d, seatY - seatT, 0.03, 0.04, PartSlot.accent),
  ];
  return FurnitureModel(parts: parts);
}

FurnitureModel _mejaBar(double w, double d, double h) {
  const top = 0.03;
  const leg = 0.04;
  const inset = 0.05;
  final footZ = d / 2 - inset - leg / 2;
  final parts = <Part>[
    Part('Daun meja', -w / 2, w / 2, h - top, h, -d / 2, d / 2),
    ..._legs(w, d, h - top, leg, inset, PartSlot.accent),
    Part(
      'Pijakan kaki',
      -w / 2 + inset + leg,
      w / 2 - inset - leg,
      0.28,
      0.30,
      footZ - 0.01,
      footZ + 0.01,
      slot: PartSlot.accent,
    ),
  ];
  return FurnitureModel(parts: parts);
}

FurnitureModel _mejaResepsionis(double w, double d, double h) {
  // Sisi depan (+Z) menghadap tamu; staf duduk di sisi belakang.
  const workY = 0.75;
  const topT = 0.03;
  const pedW = 0.42;
  const pedD = 0.5;
  final back = -d / 2;
  final panelBack = d / 2 - _t;
  final parts = <Part>[
    Part('Panel depan', -w / 2, w / 2, 0, h - topT, panelBack, d / 2),
    Part('Ledge tamu', -w / 2, w / 2, h - topT, h, d / 2 - 0.3, d / 2 + 0.03),
    Part('Sisi kiri', -w / 2, -w / 2 + _t, 0, workY - topT, back, panelBack),
    Part('Sisi kanan', w / 2 - _t, w / 2, 0, workY - topT, back, panelBack),
    Part('Meja kerja', -w / 2, w / 2, workY - topT, workY, back, panelBack),
    Part(
      'Lis aksen',
      -w / 2,
      w / 2,
      0.12,
      0.14,
      d / 2,
      d / 2 + 0.005,
      slot: PartSlot.accent,
    ),
  ];
  // Kabinet laci staf di kanan, laci menghadap ke belakang.
  final px1 = w / 2 - _t;
  final px0 = px1 - pedW;
  final pz0 = back + _t;
  final pz1 = back + pedD;
  final pedTop = workY - topT;
  parts.addAll([
    Part('Sisi laci', px0, px0 + _t, 0, pedTop, pz0, pz1),
    Part('Belakang laci', px0 + _t, px1, 0, pedTop, pz1 - _t, pz1),
  ]);
  const drawers = 3;
  final drawerH = pedTop / drawers;
  for (var i = 0; i < drawers; i++) {
    final y0 = i * drawerH + _gap / 2;
    final y1 = y0 + drawerH - _gap;
    parts
      ..add(Part('Laci ${i + 1}', px0, px1, y0, y1, back, pz0))
      ..add(
        Part(
          'Handle',
          (px0 + px1) / 2 - 0.06,
          (px0 + px1) / 2 + 0.06,
          y1 - 0.046,
          y1 - 0.034,
          back - 0.025,
          back,
          slot: PartSlot.accent,
        ),
      );
  }
  return FurnitureModel(parts: parts, drawers: drawers);
}

/// Memindah komponen dan memutarnya kelipatan 90° terhadap sumbu Y.
/// [quarterTurns] 1 membuat sisi depan lokal (+Z) menghadap +X.
List<Part> _place(
  List<Part> parts, {
  int quarterTurns = 0,
  double dx = 0,
  double dz = 0,
}) {
  (double, double) rotate(double x, double z) => switch (quarterTurns % 4) {
    0 => (x, z),
    1 => (z, -x),
    2 => (-x, -z),
    _ => (-z, x),
  };
  return [
    for (final p in parts)
      () {
        final (ax, az) = rotate(p.x0, p.z0);
        final (bx, bz) = rotate(p.x1, p.z1);
        return Part(
          p.name,
          math.min(ax, bx) + dx,
          math.max(ax, bx) + dx,
          p.y0,
          p.y1,
          math.min(az, bz) + dz,
          math.max(az, bz) + dz,
          slot: p.slot,
        );
      }(),
  ];
}

/// Deretan kabinet bawah dapur sepanjang [len], berpusat di x = 0 dengan
/// punggung di z = -d/2. Top table solid surface dan handle profil panjang.
/// [drawerColumn] adalah indeks kolom yang berisi tiga laci (null: tanpa laci).
FurnitureModel _lowerRun(double len, double d, double h, {int? drawerColumn}) {
  const plinth = 0.1;
  const topT = 0.03;
  final front = d / 2 - _t;
  final carcassTop = h - topT;
  final cols = math.max(1, (len / 0.5).round());
  final colW = len / cols;
  final parts = <Part>[
    ..._carcass(len, d, plinth, carcassTop, front),
    Part(
      'Plint',
      -len / 2 + _t,
      len / 2 - _t,
      0,
      plinth,
      front - 0.05 - _t,
      front - 0.05,
    ),
    Part(
      'Top table',
      -len / 2,
      len / 2,
      carcassTop,
      h,
      -d / 2,
      d / 2 + 0.02,
      slot: PartSlot.stone,
    ),
  ];
  for (var i = 1; i < cols; i++) {
    final x = -len / 2 + i * colW;
    parts.add(
      Part(
        'Sekat',
        x - _t / 2,
        x + _t / 2,
        plinth + _t,
        carcassTop - _t,
        -d / 2 + 0.006,
        front,
      ),
    );
  }
  var doors = 0;
  var drawers = 0;
  for (var i = 0; i < cols; i++) {
    final x0 = -len / 2 + i * colW + _gap / 2;
    final x1 = x0 + colW - _gap;
    final handleLen = (x1 - x0) * 0.8;
    if (i == drawerColumn && cols > 1) {
      const n = 3;
      final drawerH = (carcassTop - plinth) / n;
      for (var k = 0; k < n; k++) {
        final y0 = plinth + k * drawerH + _gap / 2;
        final y1 = y0 + drawerH - _gap;
        parts
          ..add(Part('Laci', x0, x1, y0, y1, front, d / 2))
          ..add(_horizontalHandle((x0 + x1) / 2, y1 - 0.02, d / 2, handleLen));
        drawers++;
      }
    } else {
      parts
        ..add(Part('Pintu', x0, x1, plinth, carcassTop, front, d / 2))
        ..add(
          _horizontalHandle((x0 + x1) / 2, carcassTop - 0.02, d / 2, handleLen),
        );
      doors++;
    }
  }
  return FurnitureModel(parts: parts, doors: doors, drawers: drawers);
}

/// Kabinet atas dapur antara [y0] dan [y1], punggung di z = -d/2.
/// Kolom terakhir dibiarkan terbuka sebagai rak pajangan, dan ada strip LED
/// di bawahnya untuk menerangi meja kerja.
FurnitureModel _upperRun(double len, double d, double y0, double y1) {
  final front = d / 2 - _t;
  final cols = math.max(2, (len / 0.5).round());
  final colW = len / cols;
  final parts = <Part>[
    ..._carcass(len, d, y0, y1, front),
    Part(
      'LED bawah kabinet',
      -len / 2 + 0.02,
      len / 2 - 0.02,
      y0 - 0.008,
      y0,
      d / 2 - 0.06,
      d / 2 - 0.04,
      slot: PartSlot.light,
    ),
  ];
  for (var i = 1; i < cols; i++) {
    final x = -len / 2 + i * colW;
    parts.add(
      Part(
        'Sekat',
        x - _t / 2,
        x + _t / 2,
        y0 + _t,
        y1 - _t,
        -d / 2 + 0.006,
        front,
      ),
    );
  }
  var doors = 0;
  for (var i = 0; i < cols; i++) {
    final x0 = -len / 2 + i * colW + _gap / 2;
    final x1 = x0 + colW - _gap;
    if (i == cols - 1) {
      // Rak terbuka: dua ambalan tanpa pintu.
      for (final f in [1 / 3, 2 / 3]) {
        final y = y0 + (y1 - y0) * f;
        parts.add(
          Part('Rak terbuka', x0, x1, y, y + _t, -d / 2 + 0.006, front),
        );
      }
      continue;
    }
    parts
      ..add(Part('Pintu atas', x0, x1, y0, y1, front, d / 2))
      ..add(
        _horizontalHandle((x0 + x1) / 2, y0 + 0.02, d / 2, (x1 - x0) * 0.8),
      );
    doors++;
  }
  return FurnitureModel(parts: parts, doors: doors);
}

FurnitureModel _kitchenL(double w, double d, double h) {
  // w = sisi A (menempel dinding belakang), d = sisi B (dinding kiri).
  const depth = 0.6;
  final runA = _lowerRun(w, depth, h, drawerColumn: (w / 0.5).round() - 1);
  // Sisi B mulai setelah top table sisi A agar tidak bertumpuk di sudut.
  final lenB = d - depth - 0.02;
  final runB = _lowerRun(lenB, depth, h, drawerColumn: 0);
  return FurnitureModel(
    parts: [
      ..._place(runA.parts, dz: -d / 2 + depth / 2),
      ..._place(
        runB.parts,
        quarterTurns: 1,
        dx: -w / 2 + depth / 2,
        dz: (-d / 2 + depth + 0.02 + d / 2) / 2,
      ),
    ],
    doors: runA.doors + runB.doors,
    drawers: runA.drawers + runB.drawers,
  );
}

FurnitureModel _kitchenLengkap(double w, double d, double h) {
  // d = kedalaman kabinet bawah; h = tinggi sampai atas kabinet atas.
  const lowerH = 0.9;
  const upperY0 = 1.45;
  const upperD = 0.35;
  final lower = _lowerRun(w, d, lowerH, drawerColumn: 0);
  final upper = _upperRun(w, upperD, upperY0, h);
  return FurnitureModel(
    parts: [
      ...lower.parts,
      Part(
        'Backsplash',
        -w / 2,
        w / 2,
        lowerH,
        upperY0,
        -d / 2,
        -d / 2 + 0.012,
        slot: PartSlot.stone,
      ),
      ..._place(upper.parts, dz: -d / 2 + upperD / 2),
    ],
    doors: lower.doors + upper.doors,
    drawers: lower.drawers,
  );
}

FurnitureModel _kitchenIsland(double w, double d, double h) {
  const topT = 0.03;
  const side = 0.03;
  const barOverhang = 0.3;
  const plinth = 0.1;
  final wi = w - 2 * side;
  final dc = math.max(0.5, d - barOverhang);
  final front = dc / 2 - _t;
  final cabTop = h - topT;
  // Badan laci dibangun menghadap +Z lalu diputar 180° agar laci menghadap
  // area masak; sisi +Z menjadi area bar dengan overhang untuk kursi.
  final cabinet = <Part>[
    ..._carcass(wi, dc, plinth, cabTop, front),
    Part(
      'Plint',
      -wi / 2 + _t,
      wi / 2 - _t,
      0,
      plinth,
      front - 0.05 - _t,
      front - 0.05,
    ),
  ];
  final cols = math.max(1, (wi / 0.6).round());
  final colW = wi / cols;
  const rows = 2;
  final rowH = (cabTop - plinth) / rows;
  for (var i = 0; i < cols; i++) {
    final x0 = -wi / 2 + i * colW + _gap / 2;
    final x1 = x0 + colW - _gap;
    for (var r = 0; r < rows; r++) {
      final y0 = plinth + r * rowH + _gap / 2;
      final y1 = y0 + rowH - _gap;
      cabinet
        ..add(Part('Laci', x0, x1, y0, y1, front, dc / 2))
        ..add(
          _horizontalHandle((x0 + x1) / 2, y1 - 0.02, dc / 2, (x1 - x0) * 0.8),
        );
    }
  }
  return FurnitureModel(
    parts: [
      Part(
        'Top waterfall',
        -w / 2,
        w / 2,
        cabTop,
        h,
        -d / 2,
        d / 2,
        slot: PartSlot.stone,
      ),
      Part(
        'Sisi waterfall kiri',
        -w / 2,
        -w / 2 + side,
        0,
        cabTop,
        -d / 2,
        d / 2,
        slot: PartSlot.stone,
      ),
      Part(
        'Sisi waterfall kanan',
        w / 2 - side,
        w / 2,
        0,
        cabTop,
        -d / 2,
        d / 2,
        slot: PartSlot.stone,
      ),
      ..._place(cabinet, quarterTurns: 2, dz: -d / 2 + dc / 2),
    ],
    drawers: cols * rows,
  );
}

FurnitureModel _lemariSliding(double w, double d, double h) {
  const plinth = 0.08;
  const railH = 0.04;
  const overlap = 0.03;
  // 6 cm di depan badan untuk dua jalur rel pintu.
  final front = d / 2 - 0.06;
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
    ..._shelves(w, d, plinth + _t, h - _t, front, 5),
    Part(
      'Rel atas',
      -w / 2,
      w / 2,
      h - railH,
      h,
      front,
      d / 2,
      slot: PartSlot.accent,
    ),
    Part(
      'Rel bawah',
      -w / 2,
      w / 2,
      plinth,
      plinth + 0.02,
      front,
      d / 2,
      slot: PartSlot.accent,
    ),
  ];
  final dividers = math.max(0, (w / 1.0).round() - 1);
  for (var i = 1; i <= dividers; i++) {
    final x = -w / 2 + i * w / (dividers + 1);
    parts.add(
      Part(
        'Sekat',
        x - _t / 2,
        x + _t / 2,
        plinth + _t,
        h - _t,
        -d / 2 + 0.006,
        front,
      ),
    );
  }
  final n = math.max(2, (w / 1.0).round());
  final doorW = (w + (n - 1) * overlap) / n;
  for (var i = 0; i < n; i++) {
    final x0 = -w / 2 + i * (doorW - overlap);
    final x1 = x0 + doorW;
    // Pintu bergantian di jalur belakang dan depan agar bisa saling melewati.
    final z0 = i.isEven ? front + 0.005 : front + 0.03;
    final z1 = z0 + 0.02;
    parts
      ..add(
        Part('Pintu geser ${i + 1}', x0, x1, plinth + 0.02, h - railH, z0, z1),
      )
      ..add(
        Part(
          'Profil pintu',
          x1 - 0.012,
          x1,
          plinth + 0.02,
          h - railH,
          z1,
          z1 + 0.008,
          slot: PartSlot.accent,
        ),
      );
    if (i == n ~/ 2) {
      parts.add(
        Part(
          'Cermin',
          x0 + 0.06,
          x1 - 0.06,
          plinth + 0.15,
          h - railH - 0.15,
          z1,
          z1 + 0.004,
          slot: PartSlot.mirror,
        ),
      );
    }
  }
  return FurnitureModel(parts: parts, slidingDoors: n);
}

FurnitureModel _lemariDisplay(double w, double d, double h) {
  const plinth = 0.08;
  final front = d / 2 - _t;
  final cols = math.max(3, (w / 0.5).round());
  final colW = w / cols;
  final openCol = cols ~/ 2;
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
  ];
  for (var i = 1; i < cols; i++) {
    final x = -w / 2 + i * colW;
    parts.add(
      Part(
        'Sekat',
        x - _t / 2,
        x + _t / 2,
        plinth + _t,
        h - _t,
        -d / 2 + 0.006,
        front,
      ),
    );
  }
  var doors = 0;
  for (var i = 0; i < cols; i++) {
    final x0 = -w / 2 + i * colW + _gap / 2;
    final x1 = x0 + colW - _gap;
    if (i == openCol) {
      // Kolom display: ambalan kaca dan LED vertikal di kedua sisi.
      final ix0 = x0 + _t / 2;
      final ix1 = x1 - _t / 2;
      for (var k = 1; k <= 4; k++) {
        final y = plinth + (h - plinth) * k / 5;
        parts.add(
          Part(
            'Ambalan kaca',
            ix0,
            ix1,
            y,
            y + 0.008,
            -d / 2 + 0.006,
            front - 0.02,
            slot: PartSlot.glass,
          ),
        );
      }
      for (final x in [ix0, ix1 - 0.01]) {
        parts.add(
          Part(
            'LED display',
            x,
            x + 0.01,
            plinth + _t,
            h - _t,
            front - 0.03,
            front - 0.02,
            slot: PartSlot.light,
          ),
        );
      }
      continue;
    }
    doors++;
    parts.add(Part('Pintu fluted', x0, x1, plinth, h, front, d / 2));
    // Alur fluted: bilah vertikal tipis setiap 3 cm.
    const pitch = 0.03;
    final flutes = ((x1 - x0 - 0.02) / pitch).floor();
    final start = (x0 + x1) / 2 - (flutes - 1) * pitch / 2;
    for (var k = 0; k < flutes; k++) {
      final cx = start + k * pitch;
      parts.add(
        Part(
          'Fluted',
          cx - 0.0075,
          cx + 0.0075,
          plinth + 0.02,
          h - 0.02,
          d / 2,
          d / 2 + 0.006,
        ),
      );
    }
    final handleX = i < openCol ? x1 - 0.03 : x0 + 0.03;
    parts.add(
      _verticalHandle(handleX, math.min(1.05, (plinth + h) / 2), d / 2 + 0.006),
    );
  }
  return FurnitureModel(parts: parts, doors: doors);
}
