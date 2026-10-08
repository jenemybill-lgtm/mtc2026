import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:toastification/toastification.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/database/database_helper.dart';
import 'package:mtc2026/models/alert_model.dart';
import 'package:mtc2026/utils/responsive.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';
import 'package:mtc2026/ui/screens/all_project_checklists_screen.dart';
import 'package:mtc2026/ui/screens/all_project_notes_screen.dart';
import 'package:mtc2026/ui/screens/digital_card_screen.dart';
import 'package:mtc2026/ui/screens/settings_screen.dart';
import 'package:mtc2026/ui/screens/company_hub_screen.dart';
import 'package:mtc2026/ui/screens/project_list_screen.dart';
import 'package:mtc2026/ui/screens/project_comparison_screen.dart';
import 'package:mtc2026/ui/screens/ai_assistant_screen.dart';
import 'package:mtc2026/ui/screens/portfolio_screen.dart';
import 'package:mtc2026/ui/screens/global_calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedCalendarDate = DateTime.now();
  DateTime _currentCalendarMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProjectProvider>(context, listen: false).fetchProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: isDesktop ? AppBar(
        title: Text("${provider.settings.companyName} (WEB)".toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        actions: [
          if (provider.isSyncing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          _buildTopSyncButton(context, "UPLOAD", Icons.cloud_upload_rounded, const Color(0xFF2563EB), () => _handleCloudUpload(context, provider)),
          const SizedBox(width: 8),
          _buildTopSyncButton(context, "DOWNLOAD", Icons.cloud_download_rounded, const Color(0xFF3A0CA3), () => _handleCloudDownload(context, provider)),
          const SizedBox(width: 12),
          _buildTopAction(context, "Ψηφιακή Κάρτα", Icons.qr_code_2, const Color(0xFFF72585), () => Navigator.push(context, MaterialPageRoute(builder: (context) => DigitalCardScreen(settings: provider.settings)))),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.settings_rounded), 
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
          ),
          const SizedBox(width: 16),
        ],
      ) : null,
      body: _buildBody(context, provider, isDesktop),
      extendBody: true, // Επιτρέπει στο περιεχόμενο να πηγαίνει κάτω από το θολό Glass Bar
      bottomNavigationBar: isDesktop ? null : GlassContainer(
        blur: 15,
        color: Colors.white.withValues(alpha: 0.7),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.8),
            Colors.white.withValues(alpha: 0.6),
          ],
        ),
        border: Border.fromBorderSide(BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 1)),
        shadowStrength: 4,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: NavigationBar(
          height: 68,
          elevation: 0,
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFF4361EE).withValues(alpha: 0.15),
          selectedIndex: 0,
          onDestinationSelected: (index) {
            if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (context) => const ProjectListScreen()));
            if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (context) => const CompanyHubScreen()));
            if (index == 3) Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined, size: 24), selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF4361EE)), label: "Αρχική"),
            NavigationDestination(icon: Icon(Icons.business_center_outlined, size: 24), selectedIcon: Icon(Icons.business_center_rounded, color: Color(0xFF4361EE)), label: "Έργα"),
            NavigationDestination(icon: Icon(Icons.location_city_outlined, size: 24), selectedIcon: Icon(Icons.location_city_rounded, color: Color(0xFF4361EE)), label: "Εταιρεία"),
            NavigationDestination(icon: Icon(Icons.settings_outlined, size: 24), selectedIcon: Icon(Icons.settings_rounded, color: Color(0xFF4361EE)), label: "Ρυθμίσεις"),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProjectProvider provider, bool isDesktop) {
    final stats = provider.dashboardStats;
    final netBalance = (stats['netIncome'] ?? 0.0) - (stats['netExpense'] ?? 0.0);

    if (isDesktop) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: ListView(
                  padding: const EdgeInsets.all(40),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("ΚΑΛΩΣΟΡΙΣΑΤΕ,", style: TextStyle(color: Colors.blueGrey.withValues(alpha: 0.6), fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
                            const SizedBox(height: 2),
                            Text(provider.settings.ownerName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 28, color: Color(0xFF0F172A), letterSpacing: -1)),
                          ],
                        ),
                        _buildGlobalSearch(context),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _PremiumStatCard(label: "ΣΥΝΟΛΟ ΕΙΣΠΡΑΞΕΩΝ", amount: stats['income']!, color: const Color(0xFF38B000), icon: Icons.trending_up_rounded),
                              const SizedBox(height: 8),
                              _PremiumStatCard(label: "ΣΥΝΟΛΟ ΕΞΟΔΩΝ", amount: stats['expense']!, color: const Color(0xFFEF4444), icon: Icons.trending_down_rounded),
                              const SizedBox(height: 8),
                              _PremiumStatCard(label: "ΥΠΟΛΟΙΠΟ ΦΠΑ", amount: stats['vatBalance'] ?? 0.0, color: Colors.orange, icon: Icons.account_balance_rounded),
                              const SizedBox(height: 8),
                              _PremiumStatCard(label: "ΚΑΘΑΡΟ ΥΠΟΛΟΙΠΟ", amount: netBalance, color: netBalance >= 0 ? const Color(0xFF4361EE) : Colors.red, isBalance: true, icon: Icons.account_balance_wallet_rounded),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 3,
                          child: _PremiumChartCard(stats: stats),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const PremiumHeader(title: "ΕΝΟΤΗΤΕΣ ΣΥΣΤΗΜΑΤΟΣ", color: const Color(0xFF4361EE)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _PremiumNavCard(title: "ΔΙΑΧΕΙΡΙΣΗ ΕΡΓΩΝ", subtitle: "${provider.projects.length} Ενεργά Έργα", icon: Icons.business_center_rounded, color: const Color(0xFF4361EE), onClick: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProjectListScreen())))),
                        const SizedBox(width: 24),
                        Expanded(child: _PremiumNavCard(title: "ΚΕΝΤΡΟ ΕΛΕΓΧΟΥ", subtitle: "Εταιρικά & Εργαλεία", icon: Icons.settings_suggest_rounded, color: const Color(0xFF4361EE), onClick: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CompanyHubScreen())))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _PremiumNavCard(
                      title: "AI ΒΟΗΘΟΣ MTC",
                      subtitle: "Ανάλυση δεδομένων & Έξυπνες προτάσεις",
                      icon: Icons.auto_awesome_rounded,
                      color: const Color(0xFF4361EE),
                      isFullWidth: true,
                      onClick: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AiAssistantScreen())),
                    ),
                    const SizedBox(height: 24),
                    _PremiumNavCard(
                      title: "ΨΗΦΙΑΚΟ PORTFOLIO",
                      subtitle: "Το 'Book' των έργων σας",
                      icon: Icons.photo_library_rounded,
                      color: const Color(0xFF4361EE),
                      isFullWidth: true,
                      onClick: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PortfolioScreen())),
                    ),
                    const SizedBox(height: 24),
                    _PremiumNavCard(
                      title: "CHECKLIST ΕΡΓΩΝ",
                      subtitle: "Συγκεντρωτική λίστα εργασιών",
                      icon: Icons.playlist_add_check_rounded,
                      color: const Color(0xFF4361EE),
                      isFullWidth: true,
                      onClick: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AllProjectChecklistsScreen())),
                    ),
                    const SizedBox(height: 24),
                    _PremiumNavCard(
                      title: "ΣΗΜΕΙΩΣΕΙΣ ΕΡΓΩΝ",
                      subtitle: "Συγκεντρωτικές σημειώσεις",
                      icon: Icons.assignment_rounded,
                      color: const Color(0xFF4361EE),
                      isFullWidth: true,
                      onClick: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AllProjectNotesScreen())),
                    ),
                  ],
                ),
              ),
              Container(
                width: 380,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border(left: BorderSide(color: Colors.black.withValues(alpha: 0.05), width: 1.5)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 40, offset: const Offset(-10, 0))],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const PremiumHeader(title: "ΗΜΕΡΟΛΟΓΙΟ", icon: Icons.calendar_month_rounded, color: Colors.blue),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.blue.withValues(alpha: 0.1), width: 1.2),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: _buildHomeCalendarView(context, provider),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(28, 24, 28, 12),
                        child: PremiumHeader(title: "ΕΙΔΟΠΟΙΗΣΕΙΣ", icon: Icons.notifications_active_rounded, color: Colors.orange),
                      ),
                      provider.alerts.isEmpty
                        ? const PremiumEmptyState(
                            title: "ΚΑΜΙΑ ΕΙΔΟΠΟΙΗΣΗ",
                            subtitle: "Όλα βαίνουν καλώς!\nΔεν έχετε καμία εκκρεμότητα.",
                            icon: Icons.notifications_off_rounded,
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: provider.alerts.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) => _buildAlertItem(context, provider.alerts[index]),
                          ),
                      Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProjectListScreen())),
                          icon: const Icon(Icons.add_business_rounded, size: 20),
                          label: const Text("ΝΕΟ ΕΡΓΟ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4361EE),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 60),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            elevation: 8,
                            shadowColor: const Color(0xFF4361EE).withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMobileHeader(provider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                _buildTopCalendarSection(context, provider),
                const SizedBox(height: 24),
                _buildBalanceCard(context, provider, stats, netBalance),
                const SizedBox(height: 24),
                _PremiumNavCard(
                  title: "ΔΙΑΧΕΙΡΙΣΗ ΕΡΓΩΝ",
                  subtitle: "${provider.projects.length} ΕΝΕΡΓΑ ΕΡΓΑ",
                  icon: Icons.business_center_rounded,
                  color: const Color(0xFF4361EE),
                  isFullWidth: true,
                  onClick: () => Navigator.push(context, PageRouteBuilder(
                    pageBuilder: (c, a1, a2) => const ProjectListScreen(),
                    transitionsBuilder: (c, a1, a2, child) => FadeTransition(opacity: a1, child: child),
                  )),
                ),
                const SizedBox(height: 16),
                _PremiumNavCard(
                  title: "ΚΕΝΤΡΟ ΕΛΕΓΧΟΥ",
                  subtitle: "ΕΤΑΙΡΕΙΑ & ΕΡΓΑΛΕΙΑ",
                  icon: Icons.settings_suggest_rounded,
                  color: const Color(0xFF4361EE),
                  isFullWidth: true,
                  onClick: () => Navigator.push(context, PageRouteBuilder(
                    pageBuilder: (c, a1, a2) => const CompanyHubScreen(),
                    transitionsBuilder: (c, a1, a2, child) => FadeTransition(opacity: a1, child: child),
                  )),
                ),
                const SizedBox(height: 16),
                _PremiumNavCard(
                  title: "AI ΒΟΗΘΟΣ MTC",
                  subtitle: "ΈΞΥΠΝΗ ΥΠΟΣΤΉΡΙΞΗ",
                  icon: Icons.auto_awesome_rounded,
                  color: const Color(0xFF4361EE),
                  isFullWidth: true,
                  onClick: () => Navigator.push(context, PageRouteBuilder(
                    pageBuilder: (c, a1, a2) => const AiAssistantScreen(),
                    transitionsBuilder: (c, a1, a2, child) => FadeTransition(opacity: a1, child: child),
                  )),
                ),
                const SizedBox(height: 16),
                _PremiumNavCard(
                  title: "ΨΗΦΙΑΚΟ PORTFOLIO",
                  subtitle: "ΤΟ BOOK ΤΩΝ ΕΡΓΩΝ ΣΑΣ",
                  icon: Icons.photo_library_rounded,
                  color: const Color(0xFF4361EE),
                  isFullWidth: true,
                  onClick: () => Navigator.push(context, PageRouteBuilder(
                    pageBuilder: (c, a1, a2) => const PortfolioScreen(),
                    transitionsBuilder: (c, a1, a2, child) => FadeTransition(opacity: a1, child: child),
                  )),
                ),
                const SizedBox(height: 16),
                _PremiumNavCard(
                  title: "CHECKLIST ΕΡΓΩΝ",
                  subtitle: "ΣΥΓΚΕΝΤΡΩΤΙΚΗ ΛΙΣΤΑ",
                  icon: Icons.playlist_add_check_rounded,
                  color: Colors.teal,
                  isFullWidth: true,
                  onClick: () => Navigator.push(context, PageRouteBuilder(
                    pageBuilder: (c, a1, a2) => const AllProjectChecklistsScreen(),
                    transitionsBuilder: (c, a1, a2, child) => FadeTransition(opacity: a1, child: child),
                  )),
                ),
                const SizedBox(height: 16),
                _PremiumNavCard(
                  title: "ΣΗΜΕΙΩΣΕΙΣ ΕΡΓΩΝ",
                  subtitle: "ΟΛΕΣ ΟΙ ΣΗΜΕΙΩΣΕΙΣ",
                  icon: Icons.assignment_rounded,
                  color: const Color(0xFF4361EE),
                  isFullWidth: true,
                  onClick: () => Navigator.push(context, PageRouteBuilder(
                    pageBuilder: (c, a1, a2) => const AllProjectNotesScreen(),
                    transitionsBuilder: (c, a1, a2, child) => FadeTransition(opacity: a1, child: child),
                  )),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCalendarSection(BuildContext context, ProjectProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF4361EE).withValues(alpha: 0.15), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: PremiumHeader(
                  title: "ΗΜΕΡΟΛΟΓΙΟ",
                  icon: Icons.calendar_month_rounded,
                  color: Color(0xFF4361EE),
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GlobalCalendarScreen())),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF4361EE).withValues(alpha: 0.1),
                  foregroundColor: const Color(0xFF4361EE),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildHomeCalendarView(context, provider),
        ],
      ),
    );
  }

  Widget _buildHomeCalendarView(BuildContext context, ProjectProvider provider) {
    final firstDay = DateTime(_currentCalendarMonth.year, _currentCalendarMonth.month, 1);
    final lastDay = DateTime(_currentCalendarMonth.year, _currentCalendarMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = (firstDay.weekday + 6) % 7;
    const dayNames = ['ΔΕΥ', 'ΤΡΙ', 'ΤΕΤ', 'ΠΕΜ', 'ΠΑΡ', 'ΣΑΒ', 'ΚΥΡ'];

    List<Widget> weeks = [];
    for (int week = 0; week < 6; week++) {
      List<Widget> dayRow = [];
      for (int dayOfWeek = 0; dayOfWeek < 7; dayOfWeek++) {
        final index = week * 7 + dayOfWeek;
        final day = index - firstWeekday + 1;

        if (day < 1 || day > daysInMonth) {
          dayRow.add(const Expanded(child: SizedBox(height: 38)));
        } else {
          final date = DateTime(_currentCalendarMonth.year, _currentCalendarMonth.month, day);
          final isSelected = date.year == _selectedCalendarDate.year && date.month == _selectedCalendarDate.month && date.day == _selectedCalendarDate.day;
          final isToday = date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day;
          final hasTasks = provider.tasks.any((t) {
            final dt = DateTime.fromMillisecondsSinceEpoch(t.date);
            return dt.year == date.year && dt.month == date.month && dt.day == date.day;
          });

          dayRow.add(
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() => _selectedCalendarDate = date);
                  showCalendarSheet(context, date, provider);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 38,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4361EE)
                        : (isToday ? const Color(0xFF4361EE).withValues(alpha: 0.12) : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                    border: isToday && !isSelected
                        ? Border.all(color: const Color(0xFF4361EE).withValues(alpha: 0.4), width: 1.2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$day",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: (isSelected || isToday) ? FontWeight.w900 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isToday ? const Color(0xFF4361EE) : const Color(0xFF1E293B)),
                        ),
                      ),
                      if (hasTasks)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      }
      weeks.add(Row(children: dayRow));
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 22),
              onPressed: () => setState(() => _currentCalendarMonth = DateTime(_currentCalendarMonth.year, _currentCalendarMonth.month - 1)),
            ),
            Text(
              DateFormat('MMMM yyyy', 'el').format(_currentCalendarMonth).toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B)),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 22),
              onPressed: () => setState(() => _currentCalendarMonth = DateTime(_currentCalendarMonth.year, _currentCalendarMonth.month + 1)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: dayNames
              .map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.blueGrey),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        Column(children: weeks),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, ProjectProvider provider, Map<String, double> stats, double netBalance) {
    return PremiumCard(
      accentColor: const Color(0xFF4361EE),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(child: PremiumHeader(title: "ΙΣΟΛΟΓΙΣΜΟΣ")),
              Row(
                children: [
                  _buildIconButton(context, Icons.cloud_upload_rounded, const Color(0xFF2563EB), () => _handleCloudUpload(context, provider)),
                  const SizedBox(width: 6),
                  _buildIconButton(context, Icons.cloud_download_rounded, const Color(0xFF3A0CA3), () => _handleCloudDownload(context, provider)),
                  const SizedBox(width: 6),
                  _buildIconButton(context, Icons.qr_code_2, const Color(0xFFF72585), () {
                    Navigator.push(context, PageRouteBuilder(
                      pageBuilder: (c, a1, a2) => DigitalCardScreen(settings: provider.settings),
                      transitionsBuilder: (c, a1, a2, child) => FadeTransition(opacity: a1, child: child),
                    ));
                  }),
                  const SizedBox(width: 6),
                  _buildIconButton(context, Icons.analytics_rounded, const Color(0xFF4361EE), () {
                    Navigator.push(context, PageRouteBuilder(
                      pageBuilder: (c, a1, a2) => const ProjectComparisonScreen(),
                      transitionsBuilder: (c, a1, a2, child) => FadeTransition(opacity: a1, child: child),
                    ));
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildStatColumn("ΕΙΣΠΡΑΞΕΙΣ (ΚΑΘΑΡΑ)", "${stats['income']!.toStringAsFixed(0)}€", const Color(0xFF38B000))),
              const SizedBox(width: 8),
              Expanded(child: _buildStatColumn("ΕΞΟΔΑ (ΚΑΘΑΡΑ)", "${stats['expense']!.toStringAsFixed(0)}€", Colors.red, crossAxisAlignment: CrossAxisAlignment.end)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildStatColumn("ΦΠΑ ΕΙΣΠΡΑΞΕΩΝ", "${(stats['vatCollected'] ?? 0.0).toStringAsFixed(0)}€", Colors.blueGrey)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatColumn("ΦΠΑ ΠΛΗΡΩΜΩΝ", "${(stats['vatPaid'] ?? 0.0).toStringAsFixed(0)}€", Colors.blueGrey, crossAxisAlignment: CrossAxisAlignment.end)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("ΚΑΘΑΡΟ ΥΠΟΛΟΙΠΟ:", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: Colors.blueGrey)),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "${netBalance.toStringAsFixed(2)} €",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: netBalance >= 0 ? const Color(0xFF4361EE) : Colors.red,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.withValues(alpha: 0.12), Colors.orange.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("ΥΠΟΛΟΙΠΟ ΦΠΑ", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 8, color: Colors.orange, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text("${(stats['vatBalance'] ?? 0.0).toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.orange, letterSpacing: -0.5)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllProjectsChecklistSection(BuildContext context, ProjectProvider provider) {
    return FutureBuilder<List<ProjectChecklistItem>>(
      future: provider.getAllProjectChecklists(),
      builder: (context, snapshot) {
        final checklist = snapshot.data ?? [];
        final completedCount = checklist.where((c) => c.isChecked).length;
        final totalCount = checklist.length;
        final progress = totalCount == 0 ? 0.0 : (completedCount / totalCount);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.teal.withValues(alpha: 0.2), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: PremiumHeader(
                      title: "CHECKLIST ΟΛΩΝ ΤΩΝ ΕΡΓΩΝ ($completedCount/$totalCount)",
                      icon: Icons.playlist_add_check_rounded,
                      color: Colors.teal,
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => _showAddHomeChecklistDialog(context, provider),
                    icon: const Icon(Icons.add_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.teal.withValues(alpha: 0.1),
                      foregroundColor: Colors.teal,
                    ),
                  ),
                ],
              ),
              if (totalCount > 0) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.teal.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (checklist.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "Δεν υπάρχουν εργασίες στη λίστα ελέγχου. Πατήστε + για προσθήκη.",
                    style: TextStyle(color: Colors.blueGrey, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                )
              else
                Column(
                  children: checklist.map((item) {
                    final proj = provider.projects.firstWhere(
                      (p) => p.id == item.projectId,
                      orElse: () => Project(name: "ΕΡΓΟ #${item.projectId}", clientName: "", address: ""),
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.teal.withValues(alpha: 0.25), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onLongPress: () => _showHomeChecklistOptionsModal(context, provider, item, proj),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: item.isChecked,
                                  activeColor: Colors.teal,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  onChanged: (v) async {
                                    await provider.updateChecklistItem(item.copyWith(isChecked: v!));
                                    setState(() {});
                                  },
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          decoration: item.isChecked ? TextDecoration.lineThrough : null,
                                          color: item.isChecked ? Colors.grey : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
                                        ),
                                        child: Text(
                                          proj.name.toUpperCase(),
                                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.teal),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
                                  onPressed: () => _showHomeChecklistOptionsModal(context, provider, item, proj),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAddHomeChecklistDialog(BuildContext context, ProjectProvider provider, {ProjectChecklistItem? itemToEdit}) {
    if (provider.projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Δεν υπάρχουν διαθέσιμα έργα. Παρακαλώ δημιουργήστε πρώτα ένα έργο.")),
      );
      return;
    }

    final controller = TextEditingController(text: itemToEdit?.title ?? "");
    int selectedProjectId = itemToEdit?.projectId ?? provider.projects.first.id;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: PremiumHeader(
            title: itemToEdit == null ? "ΝΕΑ ΕΡΓΑΣΙΑ CHECKLIST" : "ΕΠΕΞΕΡΓΑΣΙΑ ΕΡΓΑΣΙΑΣ",
            icon: Icons.playlist_add_check_rounded,
            color: Colors.teal,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedProjectId,
                  decoration: InputDecoration(
                    labelText: "Επιλογή Έργου",
                    prefixIcon: const Icon(Icons.business_center_rounded, color: Colors.teal),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  items: provider.projects.map((p) {
                    return DropdownMenuItem<int>(
                      value: p.id,
                      child: Text(p.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedProjectId = val);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: "Περιγραφή Εργασίας",
                    prefixIcon: const Icon(Icons.edit_note_rounded, color: Colors.teal),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.bold))),
            ElevatedButton(
              onPressed: () async {
                final title = controller.text.trim();
                if (title.isNotEmpty) {
                  if (itemToEdit == null) {
                    await provider.addChecklistItem(ProjectChecklistItem(
                      projectId: selectedProjectId,
                      title: title,
                    ));
                  } else {
                    await provider.updateChecklistItem(itemToEdit.copyWith(
                      projectId: selectedProjectId,
                      title: title,
                    ));
                  }
                  if (context.mounted) Navigator.pop(context);
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              child: const Text("ΑΠΟΘΗΚΕΥΣΗ", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showHomeChecklistOptionsModal(BuildContext context, ProjectProvider provider, ProjectChecklistItem item, Project proj) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.playlist_add_check_rounded, color: Colors.teal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        proj.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.teal),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.blue),
              title: const Text("Επεξεργασία Εργασίας", style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _showAddHomeChecklistDialog(context, provider, itemToEdit: item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text("Διαγραφή Εργασίας", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteHomeChecklistConfirm(context, provider, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteHomeChecklistConfirm(BuildContext context, ProjectProvider provider, ProjectChecklistItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("ΔΙΑΓΡΑΦΗ", style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text("Είστε σίγουροι ότι θέλετε να διαγράψετε αυτή την εργασία;"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
          TextButton(
            onPressed: () async {
              await provider.deleteChecklistItem(item.id, item.projectId);
              if (context.mounted) Navigator.pop(context);
              setState(() {});
            },
            child: const Text("ΔΙΑΓΡΑΦΗ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAllProjectsNotesSection(BuildContext context, ProjectProvider provider) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    return FutureBuilder<List<ProjectNote>>(
      future: DatabaseHelper().getAllProjectNotes(),
      builder: (context, snapshot) {
        final notes = snapshot.data ?? [];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.15), width: 1.2),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 4))],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const PremiumHeader(
                    title: "ΣΗΜΕΙΩΣΕΙΣ ΟΛΩΝ ΤΩΝ ΕΡΓΩΝ",
                    icon: Icons.assignment_rounded,
                    color: Color(0xFFFF9800),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => _showNoteDialog(context, provider),
                    icon: const Icon(Icons.add_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800).withValues(alpha: 0.1),
                      foregroundColor: const Color(0xFFFF9800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (notes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "Δεν υπάρχουν καταγεγραμμένες σημειώσεις στα έργα. Πατήστε + για προσθήκη.",
                    style: TextStyle(color: Colors.blueGrey, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                )
              else
                Column(
                  children: notes.map((note) => _buildNoteCardItem(context, note, provider)).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoteCardItem(BuildContext context, ProjectNote note, ProjectProvider provider) {
    final proj = provider.projects.firstWhere(
      (p) => p.id == note.projectId,
      orElse: () => Project(name: "ΕΡΓΟ #${note.projectId}", clientName: "", address: ""),
    );
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(note.dateAdded));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showNoteOptions(context, note, provider),
          onLongPress: () => _showNoteOptions(context, note, provider),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          proj.name.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFE65100)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 12, color: Colors.blueGrey),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  note.content,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w600, height: 1.4),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNoteOptions(BuildContext context, ProjectNote note, ProjectProvider provider) {
    final proj = provider.projects.firstWhere(
      (p) => p.id == note.projectId,
      orElse: () => Project(name: "ΕΡΓΟ #${note.projectId}", clientName: "", address: ""),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(proj.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFE65100))),
                ),
                const SizedBox(width: 8),
                const Text("ΕΠΙΛΟΓΕΣ ΣΗΜΕΙΩΣΗΣ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.blueGrey)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
              child: Text(note.content, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.edit_note_rounded, color: Colors.blue),
              ),
              title: const Text("Επεξεργασία Σημείωσης", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                _showNoteDialog(context, provider, noteToEdit: note);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              ),
              title: const Text("Διαγραφή Σημείωσης", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await provider.deleteProjectNote(note.projectId, note.id);
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showNoteDialog(BuildContext context, ProjectProvider provider, {ProjectNote? noteToEdit}) {
    if (provider.projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Δεν υπάρχουν έργα για προσθήκη σημείωσης.")),
      );
      return;
    }

    int? selectedProjectId = noteToEdit?.projectId ?? provider.projects.first.id;
    final noteController = TextEditingController(text: noteToEdit?.content ?? "");

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: PremiumHeader(
            title: noteToEdit == null ? "ΝΕΑ ΣΗΜΕΙΩΣΗ ΕΡΓΟΥ" : "ΕΠΕΞΕΡΓΑΣΙΑ ΣΗΜΕΙΩΣΗΣ",
            icon: noteToEdit == null ? Icons.note_add_rounded : Icons.edit_note_rounded,
            color: const Color(0xFFFF9800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedProjectId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: "Επιλογή Έργου",
                  prefixIcon: Icon(Icons.business_center_rounded),
                  border: OutlineInputBorder(),
                ),
                items: provider.projects.map((p) => DropdownMenuItem<int>(
                  value: p.id,
                  child: Text(p.name.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                )).toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedProjectId = v);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLines: 4,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: "Περιεχόμενο Σημείωσης",
                  hintText: "Γράψτε εδώ τη σημείωσή σας...",
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                final content = noteController.text.trim();
                if (content.isNotEmpty && selectedProjectId != null) {
                  if (noteToEdit == null) {
                    await provider.addProjectNote(
                      ProjectNote(
                        projectId: selectedProjectId!,
                        content: content,
                        dateAdded: DateTime.now().millisecondsSinceEpoch,
                      ),
                    );
                  } else {
                    await provider.updateProjectNote(
                      noteToEdit.copyWith(
                        projectId: selectedProjectId!,
                        content: content,
                      ),
                    );
                  }
                  if (context.mounted) Navigator.pop(context);
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
              ),
              child: Text(noteToEdit == null ? "ΠΡΟΣΘΗΚΗ" : "ΑΠΟΘΗΚΕΥΣΗ", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalSearch(BuildContext context) {
    return Container(
      width: 280,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Αναζήτηση...",
          hintStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey.withValues(alpha: 0.4)),
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: Colors.blueGrey.withValues(alpha: 0.4)),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildAlertItem(BuildContext context, SystemAlert alert) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alert.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: alert.color.withValues(alpha: 0.1), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: alert.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(alert.icon, color: alert.color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.2)),
                const SizedBox(height: 2),
                Text(alert.message, style: TextStyle(color: Colors.blueGrey.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSyncButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.9), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCloudUpload(BuildContext context, ProjectProvider provider) async {
    await DatabaseHelper().backupDatabase(autoBackup: true);
    final errorMsg = await provider.manualUploadToCloud(includePhotos: false);
    if (context.mounted) {
      final success = errorMsg == null;
      toastification.show(
        context: context,
        type: success ? ToastificationType.success : ToastificationType.error,
        style: ToastificationStyle.flatColored,
        title: Text(success ? "Επιτυχής Συγχρονισμός" : "Σφάλμα Συγχρονισμού", style: const TextStyle(fontWeight: FontWeight.w900)),
        description: Text(success ? "Τα δεδομένα σας ανέβηκαν με ασφάλεια στο Cloud." : errorMsg),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        animationBuilder: (context, animation, alignment, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, -1), end: const Offset(0, 0)).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
            child: child,
          );
        },
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );
    }
  }

  Future<void> _handleCloudDownload(BuildContext context, ProjectProvider provider) async {
    await DatabaseHelper().backupDatabase(autoBackup: true);
    final errorMsg = await provider.manualDownloadFromCloud();
    if (context.mounted) {
      final success = errorMsg == null;
      toastification.show(
        context: context,
        type: success ? ToastificationType.success : ToastificationType.error,
        style: ToastificationStyle.flatColored,
        title: Text(success ? "Λήψη Δεδομένων" : "Σφάλμα Λήψης", style: const TextStyle(fontWeight: FontWeight.w900)),
        description: Text(success ? "Τα δεδομένα λήφθηκαν επιτυχώς από το Cloud." : errorMsg),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        animationBuilder: (context, animation, alignment, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, -1), end: const Offset(0, 0)).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
            child: child,
          );
        },
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );
    }
  }

  Widget _buildTopAction(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 20),
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }

  Widget _buildIconButton(BuildContext context, IconData icon, Color color, VoidCallback onClick) {
    return InkWell(
      onTap: onClick,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color valueColor, {CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: valueColor, fontSize: 18)),
      ],
    );
  }
}

class _PremiumStatCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final bool isBalance;

  const _PremiumStatCard({required this.label, required this.amount, required this.color, required this.icon, this.isBalance = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.blueGrey.withValues(alpha: 0.5), letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "${amount.toStringAsFixed(2)} €",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: isBalance ? (amount >= 0 ? color : Colors.red) : const Color(0xFF0F172A),
                        letterSpacing: -0.5
                      )
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumChartCard extends StatelessWidget {
  final Map<String, double> stats;
  const _PremiumChartCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final income = stats['income']!;
    final expense = stats['expense']!;
    final total = income + expense;

    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const PremiumHeader(title: "ΚΑΤΑΝΟΜΗ ΤΑΜΕΙΟΥ", icon: Icons.pie_chart_outline_rounded, color: Color(0xFF1E293B)),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 6,
                    centerSpaceRadius: 50,
                    sections: [
                      if (income > 0)
                        PieChartSectionData(
                          color: const Color(0xFF38B000),
                          value: income,
                          title: '${(income / total * 100).toInt()}%',
                          radius: 40,
                          titleStyle: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 11),
                          gradient: const LinearGradient(colors: [Color(0xFF38B000), Color(0xFF1B5E20)]),
                        ),
                      if (expense > 0)
                        PieChartSectionData(
                          color: const Color(0xFFEF4444),
                          value: expense,
                          title: '${(expense / total * 100).toInt()}%',
                          radius: 40,
                          titleStyle: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 11),
                          gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFB71C1C)]),
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("ΣΥΝΟΛΙΚΗ ΡΟΗ", style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                    Text("${total.toStringAsFixed(0)}€", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: const Color(0xFF38B000), label: "Εισπράξεις"),
              const SizedBox(width: 36),
              _Legend(color: const Color(0xFFEF4444), label: "Έξοδα"),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6)])),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF334155))),
      ],
    );
  }
}

class _PremiumNavCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onClick;
  final bool isFullWidth;

  const _PremiumNavCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.onClick, this.isFullWidth = false});

  @override
  Widget build(BuildContext context) {
    return PremiumPageNavButtonFilled(
      text: title,
      subtitle: subtitle,
      icon: icon,
      onPressed: onClick,
      color: color,
    );
  }
}



  Widget _buildMobileHeader(ProjectProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 60, 32, 40),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(48)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1E293B).withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade700]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 10)],
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Καλωσήρθατε,",
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      provider.settings.ownerName.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

