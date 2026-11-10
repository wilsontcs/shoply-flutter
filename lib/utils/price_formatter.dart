/// DummyJSON sample prices are displayed in USD throughout the app.
String formatPrice(double price) {
  final List<String> parts = price.toStringAsFixed(2).split('.');
  final String whole = parts.first.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (Match match) => '${match[1]},',
  );
  return '\$$whole.${parts.last}';
}
