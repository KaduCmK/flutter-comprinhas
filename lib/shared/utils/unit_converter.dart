class UnitConverter {
  /// Retorna o multiplicador para converter a unidade da lista para a unidade do preco sugerido
  static double getConversionFactor(String listUnit, String priceUnit) {
    if (listUnit == priceUnit) return 1.0;

    final weightGroup = ['mg', 'g', 'kg', 't'];
    final volumeGroup = ['ml', 'l'];

    if (weightGroup.contains(listUnit.toLowerCase()) &&
        weightGroup.contains(priceUnit.toLowerCase())) {
      return _convertWeight(listUnit, priceUnit);
    }

    if (volumeGroup.contains(listUnit.toLowerCase()) &&
        volumeGroup.contains(priceUnit.toLowerCase())) {
      return _convertVolume(listUnit, priceUnit);
    }

    // Se nao forem da mesma familia ou for unidade abstrata (un, cx, pct), assume 1.0 ou que não é convertível matematicamente assim
    return 1.0;
  }

  static double _convertWeight(String from, String to) {
    final values = {'mg': 0.001, 'g': 1.0, 'kg': 1000.0, 't': 1000000.0};
    return values[from.toLowerCase()]! / values[to.toLowerCase()]!;
  }

  static double _convertVolume(String from, String to) {
    final values = {'ml': 1.0, 'l': 1000.0};
    return values[from.toLowerCase()]! / values[to.toLowerCase()]!;
  }
}
