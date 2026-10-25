import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:ar_furniture_configurator/geometry/furniture_builder.dart';
import 'package:ar_furniture_configurator/geometry/glb_writer.dart';
import 'package:ar_furniture_configurator/geometry/slot_materials.dart';
import 'package:ar_furniture_configurator/models/catalog.dart';
import 'package:ar_furniture_configurator/models/configuration.dart';
import 'package:ar_furniture_configurator/pricing/price_calculator.dart';
import 'package:ar_furniture_configurator/utils/currency.dart';

void main() {
  for (final type in Catalog.furniture) {
    group(type.name, () {
      final config = FurnitureConfig.initial(type);
      final model = buildFurniture(config);

      test('semua komponen bervolume dan masuk akal', () {
        for (final p in model.parts) {
          expect(p.sx, greaterThan(0), reason: p.name);
          expect(p.sy, greaterThan(0), reason: p.name);
          expect(p.sz, greaterThan(0), reason: p.name);
        }
        expect(estimatePrice(config).total, greaterThan(0));
      });

      test('ukuran luar model sama dengan ukuran pilihan', () {
        final parts = model.parts;
        final x0 = parts.map((p) => p.x0).reduce((a, b) => a < b ? a : b);
        final x1 = parts.map((p) => p.x1).reduce((a, b) => a > b ? a : b);
        final y0 = parts.map((p) => p.y0).reduce((a, b) => a < b ? a : b);
        final y1 = parts.map((p) => p.y1).reduce((a, b) => a > b ? a : b);
        expect(x1 - x0, closeTo(config.widthCm / 100, 1e-6));
        expect(y1 - y0, closeTo(config.heightCm / 100, 1e-6));
        for (final p in parts) {
          expect(p.y0, greaterThanOrEqualTo(0), reason: p.name);
        }
      });

      test('GLB valid', () {
        final glb = writeGlb(model.parts, slotMaterials(config));
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

  test('kaca, cermin, dan jok ikut dihitung', () {
    FurnitureType byKind(FurnitureKind k) =>
        Catalog.furniture.firstWhere((t) => t.kind == k);
    final pajangan = estimatePrice(
      FurnitureConfig.initial(byKind(FurnitureKind.lemariPajangan)),
    );
    final rias = estimatePrice(
      FurnitureConfig.initial(byKind(FurnitureKind.mejaRias)),
    );
    final kursi = estimatePrice(
      FurnitureConfig.initial(byKind(FurnitureKind.kursiMakan)),
    );
    expect(pajangan.glass, greaterThan(0));
    expect(rias.glass, greaterThan(0));
    expect(kursi.upholstery, greaterThan(0));
  });

  test('setiap jenis furnitur ada di katalog tepat satu kali', () {
    final kinds = Catalog.furniture.map((t) => t.kind).toList();
    expect(kinds.toSet(), FurnitureKind.values.toSet());
    expect(kinds.length, FurnitureKind.values.length);
  });

  test('format rupiah', () {
    expect(formatRupiah(4250000), 'Rp 4.250.000');
    expect(formatRupiah(500), 'Rp 500');
  });
}
