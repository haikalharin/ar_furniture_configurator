import 'package:flutter/material.dart';

import '../models/catalog.dart';
import '../models/configuration.dart';
import '../pricing/price_calculator.dart';
import '../state/quote_store.dart';
import '../utils/currency.dart';
import 'configurator_screen.dart';
import 'quote_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  /// `null` berarti semua kategori.
  FurnitureCategory? _category;

  @override
  Widget build(BuildContext context) {
    final store = QuoteScope.of(context);
    final items = Catalog.furniture
        .where((t) => _category == null || t.category == _category)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Furnitur'),
        actions: [
          IconButton(
            tooltip: 'Penawaran',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const QuoteScreen()),
            ),
            icon: Badge.count(
              count: store.items.length,
              isLabelVisible: store.items.isNotEmpty,
              child: const Icon(Icons.receipt_long_outlined),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                for (final c in <FurnitureCategory?>[
                  null,
                  ...FurnitureCategory.values,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c?.label ?? 'Semua'),
                      selected: c == _category,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) => _FurnitureCard(type: items[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _FurnitureCard extends StatelessWidget {
  const _FurnitureCard({required this.type});

  final FurnitureType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startPrice = estimatePrice(FurnitureConfig.initial(type)).total;
    return Card.filled(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ConfiguratorScreen(type: type),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Icon(
                    type.icon,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Text(type.name, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                type.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'mulai ${formatRupiah(startPrice)}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
