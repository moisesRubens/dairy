import 'package:intl/intl.dart';

final NumberFormat _brl =
    NumberFormat.currency(locale: 'pt_BR', symbol: r'R$ ', decimalDigits: 2);

/// Formata um valor monetário em Real (ex.: 1250.5 -> "R$ 1.250,50").
/// Substitui o replaceAll('.', ',') manual espalhado pelas telas antigas.
String currencyBRL(num value) => _brl.format(value);
