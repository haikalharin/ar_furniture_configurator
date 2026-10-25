import 'package:flutter/material.dart';

import '../geometry/furniture_builder.dart';
import '../models/catalog.dart';
import '../models/configuration.dart';
import '../pricing/price_calculator.dart';
import '../state/quote_store.dart';
import '../utils/currency.dart';
import '../widgets/model_preview.dart';
import '../widgets/work_drawing.dart';

class ConfiguratorScreen extends StatefulWidget {
  const ConfiguratorScreen({super.key, required this.type});

  final FurnitureType type;

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
                        label: 'Lebar',
                        range: type.width,
                        value: _config.widthCm,
                        onChanged: (v) => _update(_config.copyWith(widthCm: v)),
                      ),
                      _DimensionSlider(
                        label: 'Dalam',
                        range: type.depth,
                        value: _config.depthCm,
                        onChanged: (v) => _update(_config.copyWith(depthCm: v)),
                      ),
                      _DimensionSlider(
                        label: 'Tinggi',
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
                  child: _Breakdown(price: price, model: model),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _PriceBar(
        total: price.total,
        onAdd: () {
          QuoteScope.of(context).add(_config);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text('${type.name} ditambahkan ke penawaran')),
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 56, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: range.min,
            max: range.max,
            // Langkah 5 cm, cukup halus untuk fitting tanpa terlalu sensitif.
            divisions: ((range.max - range.min) / 5).round(),
            label: '${value.round()} cm',
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 56,
          child: Text('${value.round()} cm', textAlign: TextAlign.end),
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
  const _Breakdown({required this.price, required this.model});

  final PriceBreakdown price;
  final FurnitureModel model;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, int)>[
      (
        'Bahan & finishing (${price.panelAreaM2.toStringAsFixed(1)} m² panel)',
        price.material,
      ),
      if (price.accent > 0) ('Aksen (${model.accentCount} pcs)', price.accent),
      if (price.hardware > 0)
        (
          'Hardware (${model.doors} pintu, ${model.drawers} laci)',
          price.hardware,
        ),
      ('Ongkos kerja', price.labor),
    ];
    final style = Theme.of(context).textTheme.bodyMedium;
    return Column(
      children: [
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text(label, style: style)),
                Text(formatRupiah(value), style: style),
              ],
            ),
          ),
        const Divider(),
        Text(
          'Estimasi untuk diskusi saat fitting. Harga final setelah survei ukur ulang.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _PriceBar extends StatelessWidget {
  const _PriceBar({required this.total, required this.onAdd});

  final int total;
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
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Tambah ke penawaran'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
