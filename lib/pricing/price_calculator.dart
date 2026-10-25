import '../geometry/furniture_builder.dart';
import '../models/configuration.dart';

/// Konstanta harga mock. Sesuaikan dengan hitungan workshop.
class PricingRules {
  static const wasteFactor = 0.15; // sisa potongan panel
  static const laborShare = 0.25; // ongkos kerja sebagai porsi biaya bahan
  static const hingePerDoor = 85000; // sepasang engsel slow-motion
  static const railPerDrawer = 150000; // rel laci
  static const roundTo = 10000;
}

class PriceBreakdown {
  const PriceBreakdown({
    required this.panelAreaM2,
    required this.material,
    required this.accent,
    required this.hardware,
    required this.labor,
  });

  final double panelAreaM2;
  final int material;
  final int accent;
  final int hardware;
  final int labor;

  int get total {
    final raw = material + accent + hardware + labor;
    return (raw / PricingRules.roundTo).round() * PricingRules.roundTo;
  }
}

PriceBreakdown estimatePrice(FurnitureConfig config, [FurnitureModel? model]) {
  final m = model ?? buildFurniture(config);
  final area = m.panelAreaM2 * (1 + PricingRules.wasteFactor);
  final material = (area * config.material.pricePerM2).round();
  final accent = m.accentCount * config.accent.unitPrice;
  final hardware =
      m.doors * PricingRules.hingePerDoor +
      m.drawers * PricingRules.railPerDrawer;
  final labor =
      config.type.baseLabor + (material * PricingRules.laborShare).round();
  return PriceBreakdown(
    panelAreaM2: area,
    material: material,
    accent: accent,
    hardware: hardware,
    labor: labor,
  );
}
