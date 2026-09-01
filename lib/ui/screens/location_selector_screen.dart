import 'package:flutter/material.dart';
import 'package:mtc2026/ui/screens/material_category_picker_screen.dart';
import 'package:mtc2026/ui/screens/tool_category_picker_screen.dart';

class LocationSelectorScreen extends StatelessWidget {
  final String locationName;
  final String locationType;

  const LocationSelectorScreen({
    super.key,
    required this.locationName,
    required this.locationType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(locationName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SelectorCard(
                label: "ΕΡΓΑΛΕΙΑ",
                icon: Icons.build_rounded,
                color: const Color(0xFF3A0CA3),
                onClick: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ToolCategoryPickerScreen(
                      title: "ΕΡΓΑΛΕΙΑ ${locationName.toUpperCase()}",
                      locationType: locationType,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SelectorCard(
                label: "ΥΛΙΚΑ",
                icon: Icons.inventory_rounded,
                color: const Color(0xFF4361EE),
                onClick: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MaterialCategoryPickerScreen(
                      title: "ΥΛΙΚΑ ${locationName.toUpperCase()}",
                      locationType: locationType,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectorCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onClick;

  const _SelectorCard({required this.label, required this.icon, required this.color, required this.onClick});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    
    return InkWell(
      onTap: onClick,
      borderRadius: BorderRadius.circular(32),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        elevation: 4,
        child: Container(
          height: isDesktop ? 180 : 140,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(width: 32),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isDesktop ? 24 : 18,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded, color: color.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
