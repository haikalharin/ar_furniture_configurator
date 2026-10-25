import 'package:flutter/material.dart';

import '../models/catalog.dart';
import '../models/configuration.dart';
import '../pricing/price_calculator.dart';
import '../state/quote_store.dart';
import '../utils/currency.dart';
import 'configurator_screen.dart';
import 'quote_screen.dart';
import 'room_ar_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, this.returnTo});

  /// Bila diisi, katalog dibuka dari layar lain (mis. Tata Ruangan AR):
  /// setelah item ditambahkan, navigasi kembali ke rute dengan nama ini.
  final String? returnTo;

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
        title: Text(
          widget.returnTo == null ? 'Pilih Furnitur' : 'Tambah ke Ruangan',
        ),
        actions: [
          if (widget.returnTo == null)
            IconButton(
              tooltip: 'Tata ruangan (AR)',
              onPressed: () => openRoomAr(context),
              icon: const Icon(Icons.view_in_ar),
            ),
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
              itemBuilder: (context, i) =>
                  _FurnitureCard(type: items[i], returnTo: widget.returnTo),
            ),
          ),
        ],
      ),
    );
  }
}

class _FurnitureCard extends StatelessWidget {
  const _FurnitureCard({required this.type, this.returnTo});

  final FurnitureType type;
  final String? returnTo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startPrice = estimatePrice(FurnitureConfig.initial(type)).total;
    return Card.filled(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ConfiguratorScreen(type: type, returnTo: returnTo),
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
