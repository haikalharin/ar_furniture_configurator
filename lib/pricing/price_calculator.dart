import '../geometry/furniture_builder.dart';
import '../models/configuration.dart';

/// Konstanta harga mock. Sesuaikan dengan hitungan workshop.
class PricingRules {
  static const wasteFactor = 0.15; // sisa potongan panel
  static const laborShare = 0.25; // ongkos kerja sebagai porsi biaya bahan
  static const hingePerDoor = 85000; // sepasang engsel slow-motion
  static const railPerDrawer = 150000; // rel laci
  static const slidingSetPerDoor = 450000; // roda + rel aluminium pintu geser
  static const glassPerM2 = 350000; // kaca tempered 5 mm
  static const mirrorPerM2 = 400000; // cermin 5 mm + facet
  static const fabricPerM2 = 300000; // busa + kain jok
  static const stonePerM2 = 2500000; // top table solid surface
  static const ledPerMeter = 150000; // strip LED + profil + driver
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
    required this.stone,
    required this.lighting,
    required this.labor,
    required this.runLengthM,
  });

  /// Luas panel badan termasuk sisa potong (m²).
  final double panelAreaM2;
  final int material;
  final int accent;

  /// Engsel, rel laci, dan set pintu geser.
  final int hardware;

  /// Kaca dan cermin.
  final int glass;

  /// Jok kain (dudukan, headboard).
  final int upholstery;

  /// Top table solid surface.
  final int stone;

  /// Strip LED.
  final int lighting;
  final int labor;

  /// Panjang meter lari furnitur (m).
  final double runLengthM;

  int get total {
    final raw =
        material +
        accent +
        hardware +
        glass +
        upholstery +
        stone +
        lighting +
        labor;
    return (raw / PricingRules.roundTo).round() * PricingRules.roundTo;
  }

  /// Harga total dibagi panjang meter lari, dibulatkan seperti total.
  int get perMeterRun =>
      (total / runLengthM / PricingRules.roundTo).round() *
      PricingRules.roundTo;
}

PriceBreakdown estimatePrice(FurnitureConfig config, [FurnitureModel? model]) {
  final m = model ?? buildFurniture(config);
  final area = m.areaOf(PartSlot.body) * (1 + PricingRules.wasteFactor);
  final material = (area * config.material.pricePerM2).round();
  final accent = m.accentCount * config.accent.unitPrice;
  final hardware =
      m.doors * PricingRules.hingePerDoor +
      m.drawers * PricingRules.railPerDrawer +
      m.slidingDoors * PricingRules.slidingSetPerDoor;
  final glass =
      (m.areaOf(PartSlot.glass) * PricingRules.glassPerM2 +
              m.areaOf(PartSlot.mirror) * PricingRules.mirrorPerM2)
          .round();
  final upholstery = (m.areaOf(PartSlot.fabric) * PricingRules.fabricPerM2)
      .round();
  final stone = (m.areaOf(PartSlot.stone) * PricingRules.stonePerM2).round();
  final lighting = (m.lengthOf(PartSlot.light) * PricingRules.ledPerMeter)
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
    stone: stone,
    lighting: lighting,
    labor: labor,
    runLengthM: config.runLengthM,
  );
}
