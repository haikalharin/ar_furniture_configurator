import 'package:flutter/material.dart';

import 'screens/catalog_screen.dart';
import 'state/quote_store.dart';

void main() {
  runApp(ArFurnitureApp(store: QuoteStore()));
}

class ArFurnitureApp extends StatelessWidget {
  const ArFurnitureApp({super.key, required this.store});

  final QuoteStore store;

  @override
  Widget build(BuildContext context) {
    return QuoteScope(
      store: store,
      child: MaterialApp(
        title: 'AR Furnitur Configurator',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF8D6E63),
          useMaterial3: true,
        ),
        home: const CatalogScreen(),
      ),
    );
  }
}
