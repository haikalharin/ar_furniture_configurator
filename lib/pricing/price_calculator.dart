import '../geometry/furniture_builder.dart';
import '../models/configuration.dart';

/// Konstanta harga mock. Sesuaikan dengan hitungan workshop.
class PricingRules {
  static const wasteFactor = 0.15; // sisa potongan panel
  static const laborShare = 0.25; // ongkos kerja sebagai porsi biaya bahan
  static const hingePerDoor = 85000; // sepasang engsel slow-motion
  static const railPerDrawer = 150000; // rel laci
  static const glassPerM2 = 350000; // kaca tempered 5 mm
  static const mirrorPerM2 = 400000; // cermin 5 mm + facet
  static const fabricPerM2 = 300000; // busa + kain jok
  static const roundTo = 10000;
}

class PriceBreakdown {
  const PriceBreakdown({
    required this.panelAreaM2,
    required this.material,
    required this.accent,
    required this.hardware,
    required this.glass,
    required this.upholstery,
    required this.labor,
  });

  final double panelAreaM2;
  final int material;
  final int accent;
  final int hardware;

  /// Kaca dan cermin.
  final int glass;

  /// Jok kain (dudukan, headboard).
  final int upholstery;
  final int labor;

  int get total {
    final raw = material + accent + hardware + glass + upholstery + labor;
    return (raw / PricingRules.roundTo).round() * PricingRules.roundTo;
  }
}

PriceBreakdown estimatePrice(FurnitureConfig config, [FurnitureModel? model]) {
  final m = model ?? buildFurniture(config);
  final area = m.areaOf(PartSlot.body) * (1 + PricingRules.wasteFactor);
  final material = (area * config.material.pricePerM2).round();
  final accent = m.accentCount * config.accent.unitPrice;
  final hardware =
      m.doors * PricingRules.hingePerDoor +
      m.drawers * PricingRules.railPerDrawer;
  final glass =
      (m.areaOf(PartSlot.glass) * PricingRules.glassPerM2 +
              m.areaOf(PartSlot.mirror) * PricingRules.mirrorPerM2)
          .round();
  final upholstery = (m.areaOf(PartSlot.fabric) * PricingRules.fabricPerM2)
      .round();
  final labor =
      config.type.baseLabor + (material * PricingRules.laborShare).round();
  return PriceBreakdown(
    panelAreaM2: area,
    material: material,
    accent: accent,
    hardware: hardware,
    glass: glass,
    upholstery: upholstery,
    labor: labor,
  );
}
