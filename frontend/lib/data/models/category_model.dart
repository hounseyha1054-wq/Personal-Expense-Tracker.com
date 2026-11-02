import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String firebaseUid;
  final String name;
  final String type; // 'income' | 'expense'
  final String icon;
  final String color; // Hex string e.g. '#4F46E5'
  final bool isDefault;

  CategoryModel({
    required this.id,
    required this.firebaseUid,
    required this.name,
    required this.type,
    this.icon = 'category',
    this.color = '#4F46E5',
    this.isDefault = false,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] ?? '',
      firebaseUid: json['firebaseUid'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'expense',
      icon: json['icon'] ?? 'category',
      color: json['color'] ?? '#4F46E5',
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
    };
  }

  Color get displayColor {
    try {
      final hex = color.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF4F46E5);
    }
  }

  IconData get displayIcon {
    switch (icon) {
      case 'restaurant':
        return Icons.restaurant;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'directions_car':
        return Icons.directions_car;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'school':
        return Icons.school;
      case 'favorite':
        return Icons.favorite;
      case 'flight':
        return Icons.flight;
      case 'payments':
        return Icons.payments;
      case 'laptop_mac':
        return Icons.laptop_mac;
      case 'store':
        return Icons.store;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'trending_up':
        return Icons.trending_up;
      case 'attach_money':
        return Icons.attach_money;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'movie':
        return Icons.movie;
      case 'home':
        return Icons.home;
      default:
        return Icons.category;
    }
  }
}
