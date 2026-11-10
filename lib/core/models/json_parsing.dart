Map<String, Object?> jsonObject(Object? value) {
  if (value is! Map<String, Object?>) {
    throw const FormatException('Expected a JSON object.');
  }
  return value;
}

int nonNegativeInt(Object? value, String field) {
  if (value is! num ||
      !value.isFinite ||
      value < 0 ||
      value != value.roundToDouble()) {
    throw FormatException('Invalid $field.');
  }
  return value.toInt();
}

String jsonString(Object? value, String field) {
  if (value is! String) {
    throw FormatException('Invalid $field.');
  }
  return value;
}

List<Object?> jsonList(Object? value, String field) {
  if (value is! List<Object?>) {
    throw FormatException('Invalid $field.');
  }
  return value;
}
