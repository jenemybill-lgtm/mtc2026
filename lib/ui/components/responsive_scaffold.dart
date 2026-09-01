import 'package:flutter/material.dart';

class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          // Desktop Layout
          return Scaffold(
            appBar: AppBar(
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              actions: actions,
            ),
            body: Row(
              children: [
                NavigationRail(
                  extended: constraints.maxWidth > 1200,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  labelType: constraints.maxWidth > 1200 ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                  destinations: destinations.map((d) => NavigationRailDestination(
                    icon: d.icon,
                    selectedIcon: d.selectedIcon,
                    label: Text(d.label),
                  )).toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: body),
              ],
            ),
            floatingActionButton: floatingActionButton,
          );
        } else {
          // Mobile Layout
          return Scaffold(
            appBar: AppBar(
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              actions: actions,
            ),
            body: body,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: destinations,
            ),
            floatingActionButton: floatingActionButton,
          );
        }
      },
    );
  }
}
