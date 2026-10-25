import 'package:flutter/widgets.dart';

import '../models/configuration.dart';
import '../pricing/price_calculator.dart';
import '../utils/currency.dart';

class QuoteItem {
  QuoteItem(this.config) : id = _nextId++, price = estimatePrice(config);

  static int _nextId = 1;

  /// Penanda unik selama aplikasi berjalan, dipakai untuk file model AR.
  final int id;
  final FurnitureConfig config;
  final PriceBreakdown price;
}

/// Penawaran yang sedang disusun bersama client selama sesi fitting.
class QuoteStore extends ChangeNotifier {
  final List<QuoteItem> _items = [];
  String clientName = '';
  String room = '';

  List<QuoteItem> get items => List.unmodifiable(_items);
  int get total => _items.fold(0, (sum, item) => sum + item.price.total);

  QuoteItem add(FurnitureConfig config) {
    final item = QuoteItem(config);
    _items.add(item);
    notifyListeners();
    return item;
  }

  void removeAt(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void updateClient({String? name, String? room}) {
    clientName = name ?? clientName;
    this.room = room ?? this.room;
    notifyListeners();
  }

  /// Teks ringkasan untuk dikirim ke client, misalnya lewat WhatsApp.
  String summaryText() {
    final b = StringBuffer('Estimasi Penawaran Furnitur Custom\n');
    if (clientName.isNotEmpty) b.writeln('Client: $clientName');
    if (room.isNotEmpty) b.writeln('Ruangan: $room');
    b.writeln();
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      b
        ..writeln('${i + 1}. ${item.config.type.name}')
        ..writeln('   ${item.config.specLabel}')
        ..writeln(
          item.config.type.pricedPerMeter
              ? '   ${formatRupiah(item.price.total)} '
                    '(≈ ${formatRupiah(item.price.perMeterRun)}/m lari)'
              : '   ${formatRupiah(item.price.total)}',
        );
    }
    b
      ..writeln()
      ..writeln('Total estimasi: ${formatRupiah(total)}')
      ..writeln('*Harga estimasi, final setelah survei ukur ulang.');
    return b.toString();
  }
}

class QuoteScope extends InheritedNotifier<QuoteStore> {
  const QuoteScope({super.key, required QuoteStore store, required super.child})
    : super(notifier: store);

  static QuoteStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<QuoteScope>()!.notifier!;
}
