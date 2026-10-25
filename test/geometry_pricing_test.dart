import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:ar_furniture_configurator/geometry/furniture_builder.dart';
import 'package:ar_furniture_configurator/geometry/glb_writer.dart';
import 'package:ar_furniture_configurator/models/catalog.dart';
import 'package:ar_furniture_configurator/models/configuration.dart';
import 'package:ar_furniture_configurator/pricing/price_calculator.dart';
import 'package:ar_furniture_configurator/utils/currency.dart';

void main() {
  const materials = {
    PartSlot.body: GlbMaterial(name: 'body', rgbHex: 0xC8A273),
    PartSlot.accent: GlbMaterial(name: 'accent', rgbHex: 0x1E1E1E),
  };

  for (final type in Catalog.furniture) {
    group(type.name, () {
      final config = FurnitureConfig.initial(type);
      final model = buildFurniture(config);

      test('ukuran luar model sama dengan ukuran pilihan', () {
        final parts = model.parts;
        final x0 = parts.map((p) => p.x0).reduce((a, b) => a < b ? a : b);
        final x1 = parts.map((p) => p.x1).reduce((a, b) => a > b ? a : b);
        final y1 = parts.map((p) => p.y1).reduce((a, b) => a > b ? a : b);
        expect(x1 - x0, closeTo(config.widthCm / 100, 1e-6));
        expect(y1, closeTo(config.heightCm / 100, 1e-6));
        for (final p in parts) {
          expect(p.y0, greaterThanOrEqualTo(0), reason: p.name);
        }
      });

      test('GLB valid', () {
        final glb = writeGlb(model.parts, materials);
        final data = ByteData.sublistView(glb);
        expect(data.getUint32(0, Endian.little), 0x46546C67);
        expect(data.getUint32(8, Endian.little), glb.length);
        final jsonLen = data.getUint32(12, Endian.little);
        final json =
            jsonDecode(utf8.decode(glb.sublist(20, 20 + jsonLen)))
                as Map<String, dynamic>;
        final binLen = data.getUint32(20 + jsonLen, Endian.little);
        expect(json['buffers'][0]['byteLength'], binLen);
        expect(glb.length, 28 + jsonLen + binLen);
        for (final view in json['bufferViews'] as List) {
          expect(
            (view['byteOffset'] as int) + (view['byteLength'] as int),
            lessThanOrEqualTo(binLen),
          );
        }
      });
    });
  }

  test('harga naik saat ukuran atau material naik', () {
    final type = Catalog.furniture.first;
    final base = FurnitureConfig.initial(type);
    final bigger = base.copyWith(widthCm: type.width.max);
    final premium = base.copyWith(material: Catalog.materials.last);
    expect(estimatePrice(bigger).total, greaterThan(estimatePrice(base).total));
    expect(
      estimatePrice(premium).total,
      greaterThan(estimatePrice(base).total),
    );
    expect(estimatePrice(base).total % PricingRules.roundTo, 0);
  });

  test('format rupiah', () {
    expect(formatRupiah(4250000), 'Rp 4.250.000');
    expect(formatRupiah(500), 'Rp 500');
  });
}
