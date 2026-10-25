import 'package:flutter/material.dart';

import '../geometry/furniture_builder.dart';
import '../models/catalog.dart';
import '../models/configuration.dart';
import '../pricing/price_calculator.dart';
import '../state/quote_store.dart';
import '../utils/currency.dart';
import '../widgets/model_preview.dart';
import '../widgets/work_drawing.dart';
import 'room_ar_screen.dart';

class ConfiguratorScreen extends StatefulWidget {
  const ConfiguratorScreen({super.key, required this.type, this.returnTo});

  final FurnitureType type;

  /// Lihat [CatalogScreen.returnTo].
  final String? returnTo;

  @override
  State<ConfiguratorScreen> createState() => _ConfiguratorScreenState();
}

class _ConfiguratorScreenState extends State<ConfiguratorScreen> {
  late FurnitureConfig _config = FurnitureConfig.initial(widget.type);

  void _update(FurnitureConfig config) => setState(() => _config = config);

  @override
  Widget build(BuildContext context) {
    final model = buildFurniture(_config);
    final price = estimatePrice(_config, model);
    final type = widget.type;
    return Scaffold(
      appBar: AppBar(title: Text(type.name)),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.4,
            child: ModelPreview(config: _config),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _Section(
                  title: 'Ukuran',
                  trailing: Text(_config.sizeLabel),
                  child: Column(
                    children: [
                      _DimensionSlider(
                        label: type.widthLabel,
                        range: type.width,
                        value: _config.widthCm,
                        onChanged: (v) => _update(_config.copyWith(widthCm: v)),
                      ),
                      _DimensionSlider(
                        label: type.depthLabel,
                        range: type.depth,
                        value: _config.depthCm,
                        onChanged: (v) => _update(_config.copyWith(depthCm: v)),
                      ),
                      _DimensionSlider(
                        label: type.heightLabel,
                        range: type.height,
                        value: _config.heightCm,
                        onChanged: (v) =>
                            _update(_config.copyWith(heightCm: v)),
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: 'Material',
                  child: RadioGroup<MaterialOption>(
                    groupValue: _config.material,
                    onChanged: (v) => _update(_config.copyWith(material: v)),
                    child: Column(
                      children: [
                        for (final m in Catalog.materials)
                          RadioListTile<MaterialOption>(
                            contentPadding: EdgeInsets.zero,
                            value: m,
                            title: Text(m.name),
                            subtitle: Text(
                              '${m.note} · ${formatRupiah(m.pricePerM2)}/m²',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                _Section(
                  title: 'Warna',
                  trailing: Text(_config.color.name),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final c in Catalog.colors)
                        _Swatch(
                          color: c.color,
                          tooltip: c.name,
                          selected: c == _config.color,
                          onTap: () => _update(_config.copyWith(color: c)),
                        ),
                    ],
                  ),
                ),
                if (model.accentCount > 0)
                  _Section(
                    title: 'Aksen (handle / kaki)',
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final a in Catalog.accents)
                          ChoiceChip(
                            avatar: CircleAvatar(backgroundColor: a.color),
                            label: Text(a.name),
                            selected: a == _config.accent,
                            onSelected: (_) =>
                                _update(_config.copyWith(accent: a)),
                          ),
                      ],
                    ),
                  ),
                _Section(
                  title: 'Gambar kerja',
                  child: WorkDrawing(model: model),
                ),
                _Section(
                  title: 'Rincian estimasi',
                  child: _Breakdown(
                    price: price,
                    model: model,
                    config: _config,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _PriceBar(
        total: price.total,
        perMeter: type.pricedPerMeter ? price.perMeterRun : null,
        addLabel: widget.returnTo == null
            ? 'Tambah ke penawaran'
            : 'Taruh di ruangan',
        onAdd: () {
          QuoteScope.of(context).add(_config);
          final returnTo = widget.returnTo;
          if (returnTo != null) {
            Navigator.of(context).popUntil(ModalRoute.withName(returnTo));
            return;
          }
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('${type.name} ditambahkan ke penawaran'),
                action: SnackBarAction(
                  label: 'Tata di AR',
                  onPressed: () => openRoomAr(context),
                ),
              ),
            );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _DimensionSlider extends StatelessWidget {
  const _DimensionSlider({
    required this.label,
    required this.range,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DimensionRange range;
  final double value;
  final ValueChanged<double> onChanged;

  /// Ukuran custom: ketik angka persis dalam cm, dibatasi rentang produksi.
  Future<void> _typeExact(BuildContext context) async {
    final controller = TextEditingController(text: value.round().toString());
    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        void submit() {
          final v = double.tryParse(controller.text.replaceAll(',', '.'));
          if (v != null) Navigator.of(context).pop(v);
        }

        return AlertDialog(
          title: Text('$label (cm)'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              suffixText: 'cm',
              helperText:
                  'Antara ${range.min.round()} dan ${range.max.round()} cm',
            ),
            onSubmitted: (_) => submit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(onPressed: submit, child: const Text('Pakai')),
          ],
        );
      },
    );
    controller.dispose();
    if (result != null) onChanged(result.clamp(range.min, range.max));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(width: 72, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: range.min,
            max: range.max,
            // Langkah 5 cm, cukup halus untuk fitting tanpa terlalu sensitif.
            // Ukuran yang lebih presisi bisa diketik lewat angka di kanan.
            divisions: ((range.max - range.min) / 5).round(),
            label: '${value.round()} cm',
            onChanged: onChanged,
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _typeExact(context),
          child: Container(
            width: 72,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${value.round()} cm', textAlign: TextAlign.end),
          ),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 3 : 1,
            ),
          ),
          child: selected
              ? Icon(
                  Icons.check,
                  color: color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({
    required this.price,
    required this.model,
    required this.config,
  });

  final PriceBreakdown price;
  final FurnitureModel model;
  final FurnitureConfig config;

  String _area(double m2) => '${m2.toStringAsFixed(2).replaceAll('.', ',')} m²';

  @override
  Widget build(BuildContext context) {
    final hardware = [
      if (model.doors > 0) '${model.doors} engsel pintu',
      if (model.slidingDoors > 0) '${model.slidingDoors} set pintu geser',
      if (model.drawers > 0) '${model.drawers} rel laci',
    ].join(', ');
    final rows = <(String, String?, int)>[
      (
        'Bahan & finishing ${config.material.name}',
        '${_area(price.panelAreaM2)} × ${formatRupiah(config.material.pricePerM2)}/m²'
            ' (termasuk sisa potong ${(PricingRules.wasteFactor * 100).round()}%)',
        price.material,
      ),
      if (price.stone > 0)
        (
          'Top table solid surface',
          '${_area(model.areaOf(PartSlot.stone))} × '
              '${formatRupiah(PricingRules.stonePerM2)}/m²',
          price.stone,
        ),
      if (price.glass > 0) ('Kaca & cermin', null, price.glass),
      if (price.upholstery > 0) ('Jok kain', null, price.upholstery),
      if (price.lighting > 0)
        (
          'Lampu LED',
          '${model.lengthOf(PartSlot.light).toStringAsFixed(1).replaceAll('.', ',')} m × '
              '${formatRupiah(PricingRules.ledPerMeter)}/m',
          price.lighting,
        ),
      if (price.accent > 0)
        (
          'Aksen ${config.accent.name}',
          '${model.accentCount} pcs × ${formatRupiah(config.accent.unitPrice)}',
          price.accent,
        ),
      if (price.hardware > 0) ('Hardware', hardware, price.hardware),
      ('Ongkos kerja', null, price.labor),
    ];
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium;
    final detail = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, sub, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: style),
                      if (sub != null) Text(sub, style: detail),
                    ],
                  ),
                ),
                Text(formatRupiah(value), style: style),
              ],
            ),
          ),
        const Divider(),
        Row(
          children: [
            Expanded(child: Text('Total', style: theme.textTheme.titleSmall)),
            Text(formatRupiah(price.total), style: theme.textTheme.titleSmall),
          ],
        ),
        if (config.type.pricedPerMeter)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Setara ${formatRupiah(price.perMeterRun)} per meter lari '
              '(${price.runLengthM.toStringAsFixed(2).replaceAll('.', ',')} m)',
              style: style?.copyWith(color: theme.colorScheme.primary),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Estimasi untuk diskusi saat fitting. Harga final setelah survei ukur ulang.',
          style: detail,
        ),
      ],
    );
  }
}

class _PriceBar extends StatelessWidget {
  const _PriceBar({
    required this.total,
    required this.addLabel,
    required this.onAdd,
    this.perMeter,
  });

  final int total;

  /// Harga per meter lari, bila furnitur ini ditawarkan per meter.
  final int? perMeter;
  final String addLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Estimasi harga', style: theme.textTheme.labelMedium),
                    Text(
                      formatRupiah(total),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (perMeter != null)
                      Text(
                        '≈ ${formatRupiah(perMeter!)}/m lari',
                        style: theme.textTheme.labelSmall,
                      ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: Text(addLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
