import 'package:flutter/material.dart';

class CardItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  CardItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}