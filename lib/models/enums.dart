import 'package:flutter/material.dart';

enum AppDestinations {
  GENERAL('Γενικά', Icons.home_work, Color(0xFF607D8B)),
  ELECTRICAL('Ηλεκτρολογικά', Icons.bolt, Color(0xFFFFC107)),
  PLUMBING('Υδραυλικά', Icons.water, Color(0xFF2196F3)),
  HVAC('Θέρμανση - Ψύξη', Icons.ac_unit, Color(0xFF00BCD4)),
  FLOORS('Δάπεδα', Icons.view_quilt, Color(0xFF795548)),
  TILES('Πλακάκια', Icons.grid_view, Color(0xFF9C27B0)),
  BATHROOM('Μπάνιο', Icons.bathtub, Color(0xFF03A9F4)),
  CARPENTRY('Ξυλουργικά', Icons.foundation, Color(0xFF8D6E63)),
  PAINTING('Χρωματισμοί', Icons.color_lens, Color(0xFFE91E63)),
  DRYWALL('Γυψοσανίδες', Icons.square, Color(0xFF9E9E9E)),
  INSULATION('Θερμοπρόσοψη', Icons.texture, Color(0xFF4CAF50)),
  WINDOWS('Κουφώματα', Icons.door_front_door, Color(0xFF3F51B5)),
  BETON('Μπετά', Icons.architecture, Color(0xFF455A64)),
  METAL('Μεταλλικά', Icons.precision_manufacturing, Color(0xFF263238)),
  ENGINEERING('Μελέτες & Επιβλέψεις', Icons.design_services, Color(0xFF673AB7));

  final String label;
  final IconData icon;
  final Color color;

  const AppDestinations(this.label, this.icon, this.color);
}
