import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../money.dart';

/// A text field for typing a Taka amount (digits and one decimal point).
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.label = 'Amount',
    this.autofocus = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged == null ? null : (_) => onChanged!(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        LengthLimitingTextInputFormatter(12),
      ],
      decoration: fieldDecoration(context, label: label, prefix: '$takaSign '),
    );
  }
}

/// The amount typed into [controller] in poisha, or null when empty, invalid or zero.
int? readAmount(TextEditingController controller) {
  final v = parseTakaToPoisha(controller.text);
  return (v == null || v <= 0) ? null : v;
}

/// Plain text → "250" or "250.5", for filling a field with an existing amount.
String amountToText(int poisha) {
  final taka = poisha ~/ 100;
  final rest = poisha % 100;
  if (rest == 0) return '$taka';
  return '$taka.${rest.toString().padLeft(2, '0')}'.replaceFirst(RegExp(r'0$'), '');
}

/// The filled, borderless look used for every text field in the app.
InputDecoration fieldDecoration(BuildContext context, {String? label, String? hint, String? prefix}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixText: prefix,
    counterText: '',
    filled: true,
    fillColor: context.hisab.card,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
  );
}
