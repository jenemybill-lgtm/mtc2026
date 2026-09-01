import 'package:flutter/material.dart';

enum AlertType { warning, error, info, success }

class SystemAlert {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final AlertType type;
  final VoidCallback? onTap;

  SystemAlert({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    this.type = AlertType.info,
    this.onTap,
  });
}
