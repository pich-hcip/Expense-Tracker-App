import 'package:flutter/material.dart';

class CategoryVisuals {
  static const Map<String, IconData> iconMap = {
    'restaurant': Icons.restaurant,
    'car': Icons.directions_car,
    'shopping_bag': Icons.shopping_bag,
    'receipt': Icons.receipt_long,
    'game': Icons.videogame_asset,
    'health': Icons.health_and_safety,
    'wallet': Icons.account_balance_wallet,
    'business': Icons.business_center,
    'trending_up': Icons.trending_up,
    'gift': Icons.card_giftcard,
    'more': Icons.more_horiz,
  };

  static IconData iconFor(String key) => iconMap[key] ?? Icons.category;

  static Color colorFromHex(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  static String hexFromColor(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}