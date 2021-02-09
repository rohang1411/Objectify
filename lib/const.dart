import 'package:flutter/material.dart';

TextStyle boldStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyText1.copyWith(
      fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Segoe UI');
}
