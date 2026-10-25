import 'package:flutter/material.dart';

/// Rentang satu dimensi furnitur, dalam sentimeter.
class DimensionRange {
  const DimensionRange(this.min, this.max, this.initial);

  final double min;
  final double max;
  final double initial;
}

enum FurnitureKind {
  lemari,
  nakas,
  tempatTidur,
  mejaRias,
  bufetTv,
  rakBuku,
  mejaKopi,
  backdropTv,
  lemariPajangan,
  rakSepatu,
  kitchenBawah,
  kabinetGantung,
  mejaMakan,
  kursiMakan,
  bangku,
  mejaKerja,
  mejaBar,
  mejaResepsionis,
  kitchenL,
  kitchenLengkap,
  kitchenIsland,
  lemariSliding,
  lemariDisplay,
}

enum FurnitureCategory {
  kamar('Kamar tidur'),
  ruangTamu('Ruang tamu'),
  dapur('Dapur'),
  ruangMakan('Ruang makan'),
  komersial('Kerja & komersial');

  const FurnitureCategory(this.label);

  final String label;
}

class FurnitureType {
  const FurnitureType({
    required this.kind,
    required this.category,
    required this.name,
    required this.description,
    required this.icon,
    required this.width,
    required this.depth,
    required this.height,
    required this.baseLabor,
    this.widthLabel = 'Lebar',
    this.depthLabel = 'Dalam',
    this.heightLabel = 'Tinggi',
    this.tag,
    this.pricedPerMeter = false,
  });

  final FurnitureKind kind;
  final FurnitureCategory category;
  final String name;
  final String description;
  final IconData icon;
  final DimensionRange width;
  final DimensionRange depth;
  final DimensionRange height;

  /// Ongkos kerja dasar per unit (Rupiah), sebelum porsi persentase.
  final int baseLabor;

  final String widthLabel;
  final String depthLabel;
  final String heightLabel;

  /// Label kecil di kartu katalog, mis. 'Estetik'.
  final String? tag;

  /// Kitchen set dan lemari biasa ditawarkan per meter lari.
  final bool pricedPerMeter;
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
    // Kamar tidur
    FurnitureType(
      kind: FurnitureKind.lemari,
      category: FurnitureCategory.kamar,
      name: 'Lemari Pakaian',
      description: 'Lemari pintu ayun dengan plint bawah',
      icon: Icons.door_sliding_outlined,
      width: DimensionRange(80, 240, 160),
      depth: DimensionRange(50, 65, 60),
      height: DimensionRange(180, 260, 210),
      baseLabor: 1000000,
      pricedPerMeter: true,
    ),
    FurnitureType(
      kind: FurnitureKind.tempatTidur,
      category: FurnitureCategory.kamar,
      name: 'Tempat Tidur',
      description: 'Dipan dengan headboard berjok; lebar = ukuran kasur',
      icon: Icons.king_bed_outlined,
      width: DimensionRange(100, 200, 160),
      depth: DimensionRange(200, 220, 205),
      height: DimensionRange(90, 140, 110),
      baseLabor: 1200000,
    ),
    FurnitureType(
      kind: FurnitureKind.nakas,
      category: FurnitureCategory.kamar,
      name: 'Nakas',
      description: 'Meja samping tempat tidur dengan dua laci',
      icon: Icons.bed_outlined,
      width: DimensionRange(40, 60, 45),
      depth: DimensionRange(35, 45, 40),
      height: DimensionRange(45, 65, 55),
      baseLabor: 400000,
    ),
    FurnitureType(
      kind: FurnitureKind.mejaRias,
      category: FurnitureCategory.kamar,
      name: 'Meja Rias',
      description: 'Meja dengan laci dan cermin; tinggi termasuk cermin',
      icon: Icons.face_retouching_natural_outlined,
      width: DimensionRange(80, 140, 100),
      depth: DimensionRange(40, 50, 45),
      height: DimensionRange(140, 180, 155),
      baseLabor: 700000,
    ),
    // Ruang tamu
    FurnitureType(
      kind: FurnitureKind.bufetTv,
      category: FurnitureCategory.ruangTamu,
      name: 'Bufet TV',
      description: 'Kabinet rendah dengan pintu dan kaki besi',
      icon: Icons.tv_outlined,
      width: DimensionRange(120, 240, 180),
      depth: DimensionRange(35, 50, 40),
      height: DimensionRange(40, 65, 50),
      baseLabor: 900000,
    ),
    FurnitureType(
      kind: FurnitureKind.backdropTv,
      category: FurnitureCategory.ruangTamu,
      name: 'Backdrop TV',
      description: 'Panel dinding bergaris dengan kabinet gantung',
      icon: Icons.wallpaper,
      width: DimensionRange(180, 360, 240),
      depth: DimensionRange(30, 45, 35),
      height: DimensionRange(200, 280, 240),
      baseLabor: 1500000,
      pricedPerMeter: true,
    ),
    FurnitureType(
      kind: FurnitureKind.mejaKopi,
      category: FurnitureCategory.ruangTamu,
      name: 'Meja Kopi',
      description: 'Meja tamu dengan ambalan bawah',
      icon: Icons.coffee_outlined,
      width: DimensionRange(80, 140, 110),
      depth: DimensionRange(50, 80, 60),
      height: DimensionRange(35, 50, 42),
      baseLabor: 450000,
    ),
    FurnitureType(
      kind: FurnitureKind.rakBuku,
      category: FurnitureCategory.ruangTamu,
      name: 'Rak Buku',
      description: 'Rak terbuka, jumlah ambalan menyesuaikan tinggi',
      icon: Icons.shelves,
      width: DimensionRange(60, 200, 100),
      depth: DimensionRange(25, 45, 30),
      height: DimensionRange(80, 220, 180),
      baseLabor: 700000,
    ),
    FurnitureType(
      kind: FurnitureKind.lemariPajangan,
      category: FurnitureCategory.ruangTamu,
      name: 'Lemari Pajangan',
      description: 'Lemari display dengan pintu kaca',
      icon: Icons.window_outlined,
      width: DimensionRange(60, 160, 100),
      depth: DimensionRange(35, 45, 40),
      height: DimensionRange(160, 220, 190),
      baseLabor: 1000000,
    ),
    FurnitureType(
      kind: FurnitureKind.rakSepatu,
      category: FurnitureCategory.ruangTamu,
      name: 'Rak Sepatu',
      description: 'Kabinet sepatu tertutup untuk area pintu masuk',
      icon: Icons.inventory_2_outlined,
      width: DimensionRange(60, 150, 90),
      depth: DimensionRange(30, 40, 35),
      height: DimensionRange(80, 120, 100),
      baseLabor: 500000,
    ),
    // Dapur
    FurnitureType(
      kind: FurnitureKind.kitchenBawah,
      category: FurnitureCategory.dapur,
      name: 'Kitchen Set Bawah',
      description: 'Kabinet bawah dengan top table dan kolom laci',
      icon: Icons.countertops_outlined,
      width: DimensionRange(120, 400, 240),
      depth: DimensionRange(55, 65, 60),
      height: DimensionRange(85, 95, 90),
      baseLabor: 1500000,
      pricedPerMeter: true,
    ),
    FurnitureType(
      kind: FurnitureKind.kabinetGantung,
      category: FurnitureCategory.dapur,
      name: 'Kabinet Gantung',
      description: 'Kabinet atas dapur, terpasang 145 cm dari lantai',
      icon: Icons.kitchen_outlined,
      width: DimensionRange(60, 400, 240),
      depth: DimensionRange(30, 40, 35),
      height: DimensionRange(60, 90, 70),
      baseLabor: 1000000,
      pricedPerMeter: true,
    ),
    // Ruang makan
    FurnitureType(
      kind: FurnitureKind.mejaMakan,
      category: FurnitureCategory.ruangMakan,
      name: 'Meja Makan',
      description: 'Meja makan empat kaki',
      icon: Icons.table_restaurant_outlined,
      width: DimensionRange(120, 240, 160),
      depth: DimensionRange(70, 100, 90),
      height: DimensionRange(72, 78, 75),
      baseLabor: 800000,
    ),
    FurnitureType(
      kind: FurnitureKind.kursiMakan,
      category: FurnitureCategory.ruangMakan,
      name: 'Kursi Makan',
      description: 'Kursi kayu dengan dudukan berjok',
      icon: Icons.chair_alt_outlined,
      width: DimensionRange(42, 50, 45),
      depth: DimensionRange(45, 55, 50),
      height: DimensionRange(80, 100, 90),
      baseLabor: 350000,
    ),
    FurnitureType(
      kind: FurnitureKind.bangku,
      category: FurnitureCategory.ruangMakan,
      name: 'Bangku',
      description: 'Bangku panjang berjok dengan kaki besi',
      icon: Icons.event_seat_outlined,
      width: DimensionRange(80, 200, 120),
      depth: DimensionRange(35, 45, 40),
      height: DimensionRange(42, 48, 45),
      baseLabor: 400000,
    ),
    // Kerja & komersial
    FurnitureType(
      kind: FurnitureKind.mejaKerja,
      category: FurnitureCategory.komersial,
      name: 'Meja Kerja',
      description: 'Meja dengan kaki besi dan panel belakang',
      icon: Icons.desk_outlined,
      width: DimensionRange(80, 180, 120),
      depth: DimensionRange(50, 80, 60),
      height: DimensionRange(70, 80, 75),
      baseLabor: 600000,
    ),
    FurnitureType(
      kind: FurnitureKind.mejaBar,
      category: FurnitureCategory.komersial,
      name: 'Meja Bar Kafe',
      description: 'Meja tinggi dengan pijakan kaki besi',
      icon: Icons.local_bar_outlined,
      width: DimensionRange(100, 240, 160),
      depth: DimensionRange(40, 60, 45),
      height: DimensionRange(100, 110, 105),
      baseLabor: 600000,
    ),
    FurnitureType(
      kind: FurnitureKind.mejaResepsionis,
      category: FurnitureCategory.komersial,
      name: 'Meja Resepsionis',
      description: 'Meja depan dengan ledge tamu dan laci staf',
      icon: Icons.storefront_outlined,
      width: DimensionRange(120, 240, 180),
      depth: DimensionRange(60, 80, 70),
      height: DimensionRange(100, 115, 110),
      baseLabor: 1500000,
    ),
    // Koleksi estetik: kitchen set & lemari custom
    FurnitureType(
      kind: FurnitureKind.kitchenL,
      category: FurnitureCategory.dapur,
      name: 'Kitchen Set L',
      description: 'Kabinet bawah bentuk L, top solid surface, handle profil',
      icon: Icons.countertops,
      width: DimensionRange(150, 450, 260),
      depth: DimensionRange(120, 350, 180),
      height: DimensionRange(85, 95, 90),
      baseLabor: 2000000,
      widthLabel: 'Sisi A',
      depthLabel: 'Sisi B',
      tag: 'Estetik',
      pricedPerMeter: true,
    ),
    FurnitureType(
      kind: FurnitureKind.kitchenLengkap,
      category: FurnitureCategory.dapur,
      name: 'Kitchen Set Lengkap',
      description: 'Atas + bawah, backsplash, rak terbuka, lampu LED',
      icon: Icons.kitchen,
      width: DimensionRange(150, 600, 300),
      depth: DimensionRange(55, 65, 60),
      height: DimensionRange(200, 250, 220),
      baseLabor: 3000000,
      heightLabel: 'Tinggi total',
      tag: 'Estetik',
      pricedPerMeter: true,
    ),
    FurnitureType(
      kind: FurnitureKind.kitchenIsland,
      category: FurnitureCategory.dapur,
      name: 'Kitchen Island',
      description: 'Island waterfall dengan laci dan sisi bar',
      icon: Icons.table_bar_outlined,
      width: DimensionRange(120, 300, 180),
      depth: DimensionRange(80, 120, 90),
      height: DimensionRange(88, 95, 90),
      baseLabor: 2000000,
      tag: 'Estetik',
      pricedPerMeter: true,
    ),
    FurnitureType(
      kind: FurnitureKind.lemariSliding,
      category: FurnitureCategory.kamar,
      name: 'Lemari Sliding Cermin',
      description: 'Pintu geser dengan panel cermin dan rel aluminium',
      icon: Icons.view_week_outlined,
      width: DimensionRange(120, 400, 200),
      depth: DimensionRange(60, 70, 62),
      height: DimensionRange(200, 280, 240),
      baseLabor: 1800000,
      tag: 'Estetik',
      pricedPerMeter: true,
    ),
    FurnitureType(
      kind: FurnitureKind.lemariDisplay,
      category: FurnitureCategory.kamar,
      name: 'Lemari Fluted + Display',
      description: 'Pintu fluted, kolom display kaca dengan lampu LED',
      icon: Icons.view_column_outlined,
      width: DimensionRange(160, 400, 240),
      depth: DimensionRange(55, 65, 60),
      height: DimensionRange(200, 280, 240),
      baseLabor: 2200000,
      tag: 'Estetik',
      pricedPerMeter: true,
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
