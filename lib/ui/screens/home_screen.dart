import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/models/alert_model.dart';
import 'package:mtc2026/utils/responsive.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';
import 'package:mtc2026/ui/screens/digital_card_screen.dart';
import 'package:mtc2026/ui/screens/settings_screen.dart';
import 'package:mtc2026/ui/screens/company_hub_screen.dart';
import 'package:mtc2026/ui/screens/project_list_screen.dart';
import 'package:mtc2026/ui/screens/project_comparison_screen.dart';
import 'package:mtc2026/ui/screens/ai_assistant_screen.dart';
import 'package:mtc2026/ui/screens/portfolio_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: isDesktop ? AppBar(
        title: Text("${provider.settings.companyName} (WEB)".toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        actions: [
          if (provider.isSyncing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.fetchProjects(),
            tooltip: "Ανανέωση δεδομένων",
          ),
          _buildTopAction(context, "Ψηφιακή Κάρτα", Icons.qr_code_2, const Color(0xFFF72585), () => Navigator.push(context, MaterialPageRoute(builder: (context) => DigitalCardScreen(settings: provider.settings)))),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.settings_rounded), 
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
          ),
          const SizedBox(width: 16),
        ],
      ) : null,
      body: _buildBody(context, provider, isDesktop),
      bottomNavigationBar: isDesktop ? null : Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
        ),
        child: NavigationBar(
          height: 64,
          elevation: 0,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF4361EE).withValues(alpha: 0.1),
          selectedIndex: 0,
          onDestinationSelected: (index) {
            if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (context) => const ProjectListScreen()));
            if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (context) => const CompanyHubScreen()));
            if (index == 3) Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined, size: 22), selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF4361EE)), label: "Αρχική"),
            NavigationDestination(icon: Icon(Icons.business_center_outlined, size: 22), selectedIcon: Icon(Icons.business_center_rounded, color: Color(0xFF4361EE)), label: "Έργα"),
            NavigationDestination(icon: Icon(Icons.settings_suggest_outlined, size: 22), selectedIcon: Icon(Icons.settings_suggest_rounded, color: Color(0xFF4361EE)), label: "Εταιρεία"),
            NavigationDestination(icon: Icon(Icons.settings_outlined, size: 22), selectedIcon: Icon(Icons.settings_rounded, color: Color(0xFF4361EE)), label: "Ρυθμίσεις"),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProjectProvider provider, bool isDesktop) {
    final stats = provider.dashboardStats;
    final balance = stats['income']! - stats['expense']!;

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
                            Text("ΚΑΛΩΣΟΡΙΣΑΤΕ,", style: TextStyle(color: Colors.blueGrey.withValues(alpha: 0.5), fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
                            const SizedBox(height: 2),
                            Text(provider.settings.ownerName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 28, color: Color(0xFF0F172A), letterSpacing: -1)),
                          ],
                        ),
                        _buildGlobalSearch(context),
                      ],
                    ),
                    const SizedBox(height: 24),
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
                              _PremiumStatCard(label: "ΚΑΘΑΡΟ ΥΠΟΛΟΙΠΟ", amount: balance, color: balance >= 0 ? const Color(0xFF4361EE) : Colors.red, isBalance: true, icon: Icons.account_balance_wallet_rounded),
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
                    const PremiumHeader(title: "ΕΝΟΤΗΤΕΣ ΣΥΣΤΗΜΑΤΟΣ", color: Colors.blue),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _PremiumNavCard(title: "ΔΙΑΧΕΙΡΙΣΗ ΕΡΓΩΝ", subtitle: "${provider.projects.length} Ενεργά Έργα", icon: Icons.business_center_rounded, color: const Color(0xFF4361EE), onClick: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProjectListScreen())))),
                        const SizedBox(width: 24),
                        Expanded(child: _PremiumNavCard(title: "ΚΕΝΤΡΟ ΕΛΕΓΧΟΥ", subtitle: "Εταιρικά & Εργαλεία", icon: Icons.settings_suggest_rounded, color: const Color(0xFF7209B7), onClick: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CompanyHubScreen())))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _PremiumNavCard(
                      title: "AI ΒΟΗΘΟΣ MTC",
                      subtitle: "Ανάλυση δεδομένων & Έξυπνες προτάσεις",
                      icon: Icons.auto_awesome_rounded,
                      color: const Color(0xFFFF9800),
                      isFullWidth: true,
                      onClick: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AiAssistantScreen())),
                    ),
                    const SizedBox(height: 24),
                    _PremiumNavCard(
                      title: "ΨΗΦΙΑΚΟ PORTFOLIO",
                      subtitle: "Το 'Book' των έργων σας",
                      icon: Icons.photo_library_rounded,
                      color: Colors.teal,
                      isFullWidth: true,
                      onClick: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PortfolioScreen())),
                    ),
                    const SizedBox(height: 24),
                    _buildSyncControl(context, provider),
                  ],
                ),
              ),
              Container(
                width: 380,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(left: BorderSide(color: Colors.black.withValues(alpha: 0.04), width: 1.5)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 40, offset: const Offset(-10, 0))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(32, 48, 32, 24),
                      child: PremiumHeader(title: "ΕΙΔΟΠΟΙΗΣΕΙΣ", icon: Icons.notifications_active_rounded, color: Colors.orange),
                    ),
                    Expanded(
                      child: provider.alerts.isEmpty
                        ? const Center(child: Text("Δεν υπάρχουν νέες ειδοποιήσεις", style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: provider.alerts.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) => _buildAlertItem(context, provider.alerts[index]),
                          ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProjectListScreen())),
                        icon: const Icon(Icons.add_business_rounded, size: 20),
                        label: const Text("ΝΕΟ ΕΡΓΟ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4361EE),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 70),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 8,
                          shadowColor: const Color(0xFF4361EE).withValues(alpha: 0.4),
                        ),
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

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildMobileHeader(provider),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              PremiumCard(
                accentColor: const Color(0xFF4361EE),
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const PremiumHeader(title: "ΙΣΟΛΟΓΙΣΜΟΣ"),
                        Row(
                          children: [
                            _buildIconButton(context, Icons.qr_code_2, const Color(0xFFF72585), () {
                              Navigator.push(context, PageRouteBuilder(
                                pageBuilder: (c, a1, a2) => DigitalCardScreen(settings: provider.settings),
                                transitionsBuilder: (c, a1, a2, child) => FadeTransition(opacity: a1, child: child),
                              ));
                            }),
                            const SizedBox(width: 8),
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
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _buildStatColumn("ΕΙΣΠΡΑΞΕΙΣ (ΚΑΘΑΡΑ)", "${stats['income']!.toStringAsFixed(0)}€", const Color(0xFF38B000))),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatColumn("ΕΞΟΔΑ (ΚΑΘΑΡΑ)", "${stats['expense']!.toStringAsFixed(0)}€", Colors.red, crossAxisAlignment: CrossAxisAlignment.end)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _buildStatColumn("ΦΠΑ ΕΙΣΠΡΑΞΕΩΝ", "${(stats['vatCollected'] ?? 0.0).toStringAsFixed(0)}€", Colors.blueGrey)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatColumn("ΦΠΑ ΠΛΗΡΩΜΩΝ", "${(stats['vatPaid'] ?? 0.0).toStringAsFixed(0)}€", Colors.blueGrey, crossAxisAlignment: CrossAxisAlignment.end)),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Divider(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("ΚΑΘΑΡΟ ΥΠΟΛΟΙΠΟ:", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.blueGrey)),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "${balance.toStringAsFixed(2)} €",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                  color: balance >= 0 ? const Color(0xFF4361EE) : Colors.red,
                                  letterSpacing: -1
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.orange.withValues(alpha: 0.12), Colors.orange.withValues(alpha: 0.05)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text("ΥΠΟΛΟΙΠΟ ΦΠΑ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 8, color: Colors.orange, letterSpacing: 0.5)),
                              const SizedBox(height: 2),
                              Text("${(stats['vatBalance'] ?? 0.0).toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.orange, letterSpacing: -0.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
                color: const Color(0xFF7209B7),
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
                color: const Color(0xFFFF9800),
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
                color: Colors.teal,
                isFullWidth: true,
                onClick: () => Navigator.push(context, PageRouteBuilder(
                  pageBuilder: (c, a1, a2) => const PortfolioScreen(),
                  transitionsBuilder: (c, a1, a2, child) => FadeTransition(opacity: a1, child: child),
                )),
              ),
              const SizedBox(height: 24),
              _buildSyncControl(context, provider),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSyncControl(BuildContext context, ProjectProvider provider) {
    return PremiumCard(
      accentColor: Colors.blue,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumHeader(title: "ΣΥΓΧΡΟΝΙΣΜΟΣ CLOUD", icon: Icons.cloud_sync_rounded, color: Colors.blueGrey),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: provider.isSyncing ? null : () async {
                    final success = await provider.manualUploadToCloud();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(success ? "Τα δεδομένα ανέβηκαν επιτυχώς!" : "Αποτυχία ανεβάσματος."),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ));
                    }
                  },
                  icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                  label: const Text("UPLOAD", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: provider.isSyncing ? null : () async {
                    final success = await provider.manualDownloadFromCloud();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(success ? "Τα δεδομένα λήφθηκαν επιτυχώς!" : "Αποτυχία λήψης."),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ));
                    }
                  },
                  icon: const Icon(Icons.cloud_download_rounded, size: 18),
                  label: const Text("DOWNLOAD", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3A0CA3), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ],
          ),
        ],
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
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: valueColor, fontSize: 18)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 1.0),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 1.0),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onClick,
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.2, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text(subtitle.toUpperCase(), style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: Colors.blueGrey.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

  Widget _buildMobileHeader(ProjectProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 60, 32, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1E293B), const Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
          if (provider.settings.logoUri != null && provider.settings.logoUri!.isNotEmpty) ...[
            const SizedBox(height: 40),
            Container(
              height: 90,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Image.file(File(provider.settings.logoUri!), fit: BoxFit.contain),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIconButton(BuildContext context, IconData icon, Color color, VoidCallback onTap) {
    return IconButton.filledTonal(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 20),
      style: IconButton.styleFrom(backgroundColor: color.withValues(alpha: 0.1)),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color, {CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.blueGrey.withValues(alpha: 0.6), letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color, letterSpacing: -0.5)),
      ],
    );
  }

