import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/screens/home_screen.dart';
import 'package:mtc2026/ui/screens/project_management_hub_screen.dart';
import 'package:mtc2026/ui/screens/project_overview_screen.dart';
import 'package:mtc2026/ui/screens/quote_categories_screen.dart';
import 'package:mtc2026/ui/screens/project_calendar_screen.dart';
import 'package:mtc2026/ui/screens/summary_screen.dart';

class ProjectMainScreen extends StatefulWidget {
  final Project project;

  const ProjectMainScreen({super.key, required this.project});

  @override
  State<ProjectMainScreen> createState() => _ProjectMainScreenState();
}

class _ProjectMainScreenState extends State<ProjectMainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProjectProvider>(context, listen: false).fetchProjectData(widget.project.id);
    });
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return ProjectOverviewScreen(
          project: widget.project,
          onModuleClick: (i) {
            setState(() => _selectedIndex = i);
          },
        );
      case 1:
        return QuoteCategoriesScreen(project: widget.project);
      case 2:
        return SummaryScreen(project: widget.project, showAppBar: false);
      case 3:
        return ProjectCalendarScreen(project: widget.project);
      case 4:
        return ProjectManagementHubScreen(project: widget.project);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getTitle(_selectedIndex), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.5)),
            Text(widget.project.name.toUpperCase(), style: const TextStyle(fontSize: 10, color: Color(0xFF1E40AF), fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: "Επιστροφή στη λίστα",
        ),
      ),
      floatingActionButton: _buildFAB(),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Material(
            color: const Color(0xFFF1F5F9),
            child: _getScreen(_selectedIndex),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
        ),
        child: NavigationBar(
          height: 64,
          elevation: 0,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF1E40AF).withValues(alpha: 0.1),
          selectedIndex: _selectedIndex + 1,
          onDestinationSelected: (index) {
            if (index == 0) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            } else {
              setState(() => _selectedIndex = index - 1);
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, size: 22),
              selectedIcon: Icon(Icons.home_rounded, size: 22, color: Color(0xFF1E40AF)),
              label: "Αρχική",
            ),
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, size: 22),
              selectedIcon: Icon(Icons.dashboard_rounded, size: 22, color: Color(0xFF1E40AF)),
              label: "Επισκόπηση",
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined, size: 22),
              selectedIcon: Icon(Icons.assignment_rounded, size: 22, color: Color(0xFF1E40AF)),
              label: "Προσφορά",
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined, size: 22),
              selectedIcon: Icon(Icons.analytics_rounded, size: 22, color: Color(0xFF1E40AF)),
              label: "Σύνολο",
            ),
            NavigationDestination(
              icon: Icon(Icons.event_note_outlined, size: 22),
              selectedIcon: Icon(Icons.event_note_rounded, size: 22, color: Color(0xFF1E40AF)),
              label: "Ημερολόγιο",
            ),
            NavigationDestination(
              icon: Icon(Icons.dashboard_customize_outlined, size: 22),
              selectedIcon: Icon(Icons.dashboard_customize_rounded, size: 22, color: Color(0xFF1E40AF)),
              label: "Διαχείριση",
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0: return "ΕΠΙΣΚΟΠΗΣΗ ΕΡΓΟΥ";
      case 1: return "ΠΡΟΣΦΟΡΑ";
      case 2: return "ΣΥΝΟΨΗ ΠΡΟΣΦΟΡΑΣ";
      case 3: return "ΗΜΕΡΟΛΟΓΙΟ ΕΡΓΟΥ";
      case 4: return "ΔΙΑΧΕΙΡΙΣΗ ΕΡΓΟΥ";
      default: return "";
    }
  }

  Widget? _buildFAB() {
    if (_selectedIndex == 3) {
      return FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      );
    }
    return null;
  }
}
