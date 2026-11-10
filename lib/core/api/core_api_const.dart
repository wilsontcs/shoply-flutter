abstract final class CoreApiConst {
  static const String baseUrl = 'https://dummyjson.com';
  static const String products = '/products';
  static const String search = '/products/search';
  static const int pageSize = 20;

  static String product(int id) => '$products/$id';
}
