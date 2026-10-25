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
  const FurnitureModel({required this.parts, this.doors = 0, this.drawers = 0});

  final List<Part> parts;
  final int doors;
  final int drawers;

  int get accentCount => parts.where((p) => p.slot == PartSlot.accent).length;

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

FurnitureModel _kitchenBawah(double w, double d, double h) {
  const plinth = 0.1;
  const topT = 0.03;
  final front = d / 2 - _t;
  final carcassTop = h - topT;
  final cols = math.max(2, (w / 0.5).round());
  final colW = w / cols;
  final parts = <Part>[
    ..._carcass(w, d, plinth, carcassTop, front),
    Part(
      'Plint',
      -w / 2 + _t,
      w / 2 - _t,
      0,
      plinth,
      front - 0.05 - _t,
      front - 0.05,
    ),
    Part('Top table', -w / 2, w / 2, carcassTop, h, -d / 2, d / 2 + 0.02),
  ];
  for (var i = 1; i < cols; i++) {
    final x = -w / 2 + i * colW;
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
  // Kolom paling kiri berisi tiga laci, sisanya pintu.
  const drawers = 3;
  final drawerH = (carcassTop - plinth) / drawers;
  final dx0 = -w / 2 + _gap / 2;
  final dx1 = -w / 2 + colW - _gap / 2;
  for (var i = 0; i < drawers; i++) {
    final y0 = plinth + i * drawerH + _gap / 2;
    final y1 = y0 + drawerH - _gap;
    parts
      ..add(Part('Laci ${i + 1}', dx0, dx1, y0, y1, front, d / 2))
      ..add(_horizontalHandle((dx0 + dx1) / 2, y1 - 0.04, d / 2));
  }
  parts.addAll(
    _doorRow(
      x0: -w / 2 + colW,
      x1: w / 2,
      y0: plinth,
      y1: carcassTop,
      front: front,
      face: d / 2,
      count: cols - 1,
    ),
  );
  return FurnitureModel(parts: parts, doors: cols - 1, drawers: drawers);
}

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
