import 'package:flutter/material.dart';

/// Rentang satu dimensi furnitur, dalam sentimeter.
class DimensionRange {
  const DimensionRange(this.min, this.max, this.initial);

  final double min;
  final double max;
  final double initial;
}

enum FurnitureKind { mejaKerja, lemari, rakBuku, bufetTv, nakas, mejaMakan }

class FurnitureType {
  const FurnitureType({
    required this.kind,
    required this.name,
    required this.description,
    required this.icon,
    required this.width,
    required this.depth,
    required this.height,
    required this.baseLabor,
  });

  final FurnitureKind kind;
  final String name;
  final String description;
  final IconData icon;
  final DimensionRange width;
  final DimensionRange depth;
  final DimensionRange height;

  /// Ongkos kerja dasar per unit (Rupiah), sebelum porsi persentase.
  final int baseLabor;
}

class MaterialOption {
  const MaterialOption({
    required this.id,
    required this.name,
    required this.note,
    required this.pricePerM2,
    required this.roughness,
  });

  final String id;
  final String name;
  final String note;

  /// Harga bahan + finishing per m² panel (Rupiah).
  final int pricePerM2;
  final double roughness;
}

class ColorOption {
  const ColorOption(this.id, this.name, this.hex);

  final String id;
  final String name;
  final int hex;

  Color get color => Color(0xFF000000 | hex);
}

class AccentOption {
  const AccentOption({
    required this.id,
    required this.name,
    required this.hex,
    required this.metallic,
    required this.roughness,
    required this.unitPrice,
  });

  final String id;
  final String name;
  final int hex;
  final double metallic;
  final double roughness;

  /// Harga per komponen aksen (handle atau kaki besi), Rupiah.
  final int unitPrice;

  Color get color => Color(0xFF000000 | hex);
}

/// Data katalog mock. Ganti angka harga di sini sesuai daftar harga workshop.
class Catalog {
  static const furniture = <FurnitureType>[
    FurnitureType(
      kind: FurnitureKind.lemari,
      name: 'Lemari Pakaian',
      description: 'Lemari pintu ayun dengan plint bawah',
      icon: Icons.door_sliding_outlined,
      width: DimensionRange(80, 240, 160),
      depth: DimensionRange(50, 65, 60),
      height: DimensionRange(180, 260, 210),
      baseLabor: 1000000,
    ),
    FurnitureType(
      kind: FurnitureKind.bufetTv,
      name: 'Bufet TV',
      description: 'Kabinet rendah dengan pintu dan kaki besi',
      icon: Icons.tv_outlined,
      width: DimensionRange(120, 240, 180),
      depth: DimensionRange(35, 50, 40),
      height: DimensionRange(40, 65, 50),
      baseLabor: 900000,
    ),
    FurnitureType(
      kind: FurnitureKind.rakBuku,
      name: 'Rak Buku',
      description: 'Rak terbuka, jumlah ambalan menyesuaikan tinggi',
      icon: Icons.shelves,
      width: DimensionRange(60, 200, 100),
      depth: DimensionRange(25, 45, 30),
      height: DimensionRange(80, 220, 180),
      baseLabor: 700000,
    ),
    FurnitureType(
      kind: FurnitureKind.mejaKerja,
      name: 'Meja Kerja',
      description: 'Meja dengan kaki besi dan panel belakang',
      icon: Icons.desk_outlined,
      width: DimensionRange(80, 180, 120),
      depth: DimensionRange(50, 80, 60),
      height: DimensionRange(70, 80, 75),
      baseLabor: 600000,
    ),
    FurnitureType(
      kind: FurnitureKind.mejaMakan,
      name: 'Meja Makan',
      description: 'Meja makan empat kaki',
      icon: Icons.table_restaurant_outlined,
      width: DimensionRange(120, 240, 160),
      depth: DimensionRange(70, 100, 90),
      height: DimensionRange(72, 78, 75),
      baseLabor: 800000,
    ),
    FurnitureType(
      kind: FurnitureKind.nakas,
      name: 'Nakas',
      description: 'Meja samping tempat tidur dengan dua laci',
      icon: Icons.bed_outlined,
      width: DimensionRange(40, 60, 45),
      depth: DimensionRange(35, 45, 40),
      height: DimensionRange(45, 65, 55),
      baseLabor: 400000,
    ),
  ];

  static const materials = <MaterialOption>[
    MaterialOption(
      id: 'hpl',
      name: 'Multiplek + HPL',
      note: 'Paling ekonomis, tahan gores',
      pricePerM2: 300000,
      roughness: 0.6,
    ),
    MaterialOption(
      id: 'duco',
      name: 'MDF Duco',
      note: 'Cat semprot halus, warna bebas',
      pricePerM2: 450000,
      roughness: 0.35,
    ),
    MaterialOption(
      id: 'veneer',
      name: 'Plywood Veneer',
      note: 'Serat kayu asli, finishing melamik',
      pricePerM2: 550000,
      roughness: 0.55,
    ),
    MaterialOption(
      id: 'jati',
      name: 'Kayu Jati Solid',
      note: 'Premium, paling awet',
      pricePerM2: 1200000,
      roughness: 0.5,
    ),
  ];

  static const colors = <ColorOption>[
    ColorOption('oak', 'Natural Oak', 0xC8A273),
    ColorOption('jati', 'Jati', 0x9A6B3F),
    ColorOption('walnut', 'Walnut', 0x6B4A33),
    ColorOption('putih', 'Putih Doff', 0xEEEBE5),
    ColorOption('charcoal', 'Abu Charcoal', 0x3D3F42),
    ColorOption('sage', 'Sage Green', 0x9CAF88),
    ColorOption('navy', 'Navy', 0x2C3E5A),
    ColorOption('terracotta', 'Terracotta', 0xB8643F),
  ];

  static const accents = <AccentOption>[
    AccentOption(
      id: 'hitam',
      name: 'Hitam Doff',
      hex: 0x1E1E1E,
      metallic: 0.3,
      roughness: 0.6,
      unitPrice: 45000,
    ),
    AccentOption(
      id: 'gold',
      name: 'Gold Brushed',
      hex: 0xC9A55A,
      metallic: 1,
      roughness: 0.35,
      unitPrice: 75000,
    ),
    AccentOption(
      id: 'stainless',
      name: 'Stainless',
      hex: 0xC0C4C8,
      metallic: 1,
      roughness: 0.25,
      unitPrice: 60000,
    ),
  ];
}
