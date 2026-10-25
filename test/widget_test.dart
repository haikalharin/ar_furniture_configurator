import 'package:flutter_test/flutter_test.dart';

import 'package:ar_furniture_configurator/main.dart';
import 'package:ar_furniture_configurator/models/catalog.dart';
import 'package:ar_furniture_configurator/models/configuration.dart';
import 'package:ar_furniture_configurator/state/quote_store.dart';

void main() {
  testWidgets('katalog menampilkan semua jenis furnitur', (tester) async {
    await tester.pumpWidget(ArFurnitureApp(store: QuoteStore()));
    expect(find.text('Pilih Furnitur'), findsOneWidget);
    expect(find.text(Catalog.furniture.first.name), findsOneWidget);
  });

  test('ringkasan penawaran memuat item dan total', () {
    final store = QuoteStore()
      ..updateClient(name: 'Ibu Sari', room: 'Kamar utama')
      ..add(FurnitureConfig.initial(Catalog.furniture.first));
    final text = store.summaryText();
    expect(text, contains('Ibu Sari'));
    expect(text, contains(Catalog.furniture.first.name));
    expect(text, contains('Total estimasi'));
  });
}
