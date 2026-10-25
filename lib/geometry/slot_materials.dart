import '../models/configuration.dart';
import 'furniture_builder.dart';
import 'glb_writer.dart';

/// Material 3D untuk setiap slot: badan dan aksen mengikuti pilihan client,
/// kaca, cermin, dan jok kain memakai tampilan tetap.
Map<PartSlot, GlbMaterial> slotMaterials(FurnitureConfig config) => {
  PartSlot.body: GlbMaterial(
    name: '${config.material.name} ${config.color.name}',
    rgbHex: config.color.hex,
    roughness: config.material.roughness,
  ),
  PartSlot.accent: GlbMaterial(
    name: config.accent.name,
    rgbHex: config.accent.hex,
    metallic: config.accent.metallic,
    roughness: config.accent.roughness,
  ),
  PartSlot.glass: const GlbMaterial(
    name: 'Kaca',
    rgbHex: 0xDDEEF0,
    roughness: 0.05,
    alpha: 0.3,
  ),
  PartSlot.mirror: const GlbMaterial(
    name: 'Cermin',
    rgbHex: 0xE8ECEE,
    metallic: 1,
    roughness: 0.12,
  ),
  PartSlot.fabric: const GlbMaterial(
    name: 'Jok kain',
    rgbHex: 0xB9B2A6,
    roughness: 0.95,
  ),
};
