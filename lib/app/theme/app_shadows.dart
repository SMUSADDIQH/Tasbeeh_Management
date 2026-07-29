import 'package:flutter/material.dart';

abstract final class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x140F172A), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> cardDark = [
    BoxShadow(color: Color(0x52000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
}
