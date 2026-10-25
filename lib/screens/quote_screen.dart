import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/quote_store.dart';
import '../utils/currency.dart';

class QuoteScreen extends StatelessWidget {
  const QuoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = QuoteScope.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Penawaran')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            initialValue: store.clientName,
            decoration: const InputDecoration(
              labelText: 'Nama client',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => store.updateClient(name: v),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: store.room,
            decoration: const InputDecoration(
              labelText: 'Ruangan (mis. Kamar utama)',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => store.updateClient(room: v),
          ),
          const SizedBox(height: 16),
          if (store.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Text(
                'Belum ada item. Pilih furnitur, atur ukuran dan material, '
                'lalu tekan "Tambah ke penawaran".',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          for (var i = 0; i < store.items.length; i++)
            Card.outlined(
              child: ListTile(
                leading: Icon(store.items[i].config.type.icon),
                title: Text(store.items[i].config.type.name),
                subtitle: Text(store.items[i].config.specLabel),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatRupiah(store.items[i].price.total)),
                    InkWell(
                      onTap: () => store.removeAt(i),
                      child: Text(
                        'Hapus',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total estimasi', style: theme.textTheme.labelMedium),
                    Text(
                      formatRupiah(store.total),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: store.items.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(
                          ClipboardData(text: store.summaryText()),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Ringkasan disalin, tinggal tempel ke WhatsApp',
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.copy),
                label: const Text('Salin ringkasan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
