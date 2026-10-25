import 'catalog.dart';

/// Pilihan client untuk satu unit furnitur. Dimensi dalam sentimeter.
class FurnitureConfig {
  const FurnitureConfig({
    required this.type,
    required this.widthCm,
    required this.depthCm,
    required this.heightCm,
    required this.material,
    required this.color,
    required this.accent,
  });

  factory FurnitureConfig.initial(FurnitureType type) => FurnitureConfig(
    type: type,
    widthCm: type.width.initial,
    depthCm: type.depth.initial,
    heightCm: type.height.initial,
    material: Catalog.materials.first,
    color: Catalog.colors.first,
    accent: Catalog.accents.first,
  );

  final FurnitureType type;
  final double widthCm;
  final double depthCm;
  final double heightCm;
  final MaterialOption material;
  final ColorOption color;
  final AccentOption accent;

  FurnitureConfig copyWith({
    double? widthCm,
    double? depthCm,
    double? heightCm,
    MaterialOption? material,
    ColorOption? color,
    AccentOption? accent,
  }) => FurnitureConfig(
    type: type,
    widthCm: widthCm ?? this.widthCm,
    depthCm: depthCm ?? this.depthCm,
    heightCm: heightCm ?? this.heightCm,
    material: material ?? this.material,
    color: color ?? this.color,
    accent: accent ?? this.accent,
  );

  /// Panjang meter lari untuk harga per meter. Kitchen set L dihitung
  /// dari kedua sisinya.
  double get runLengthM => type.kind == FurnitureKind.kitchenL
      ? (widthCm + depthCm) / 100
      : widthCm / 100;

  String get sizeLabel =>
      '${widthCm.round()} × ${depthCm.round()} × ${heightCm.round()} cm';

  String get specLabel =>
      '$sizeLabel · ${material.name} · ${color.name} · aksen ${accent.name}';
}
