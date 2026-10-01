import 'package:flutter/material.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';
import 'package:mtc2026/ui/screens/global_payroll_screen.dart';
import 'package:mtc2026/ui/screens/manage_prices_screen.dart';
import 'package:mtc2026/ui/screens/market_archive_screen.dart';
import 'package:mtc2026/ui/screens/job_recipes_screen.dart';

class JobsManagementScreen extends StatelessWidget {
  const JobsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        title: const Text("ΔΙΑΧΕΙΡΙΣΗ ΕΡΓΑΣΙΩΝ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
          child: ListView(
            padding: EdgeInsets.all(isDesktop ? 36.0 : 20.0),
            children: [
              // Header Banner
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isDesktop ? 32 : 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF059669).withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 6)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                      ),
                      child: const Icon(Icons.engineering_rounded, color: Colors.white, size: 36),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "ΚΕΝΤΡΟ ΕΡΓΑΣΙΩΝ & ΤΙΜΟΛΟΓΗΣΗΣ",
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Ταμείο, Τιμοκατάλογος & Συνταγές",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              _buildHeaderChip("Κεντρικό Ταμείο", Icons.account_balance_wallet_rounded),
                              _buildHeaderChip("Πρότυπα Τιμών", Icons.style_rounded),
                              _buildHeaderChip("Συνταγές Έργων", Icons.auto_fix_high_rounded),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              const PremiumHeader(title: "ΕΝΟΤΗΤΕΣ ΕΡΓΑΣΙΩΝ", icon: Icons.engineering_rounded, color: Color(0xFF059669)),
              const SizedBox(height: 20),

              // Modules Grid
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 2 : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 110,
                ),
                children: [
                  _JobModuleCard(
                    title: "ΚΕΝΤΡΙΚΟ ΤΑΜΕΙΟ",
                    subtitle: "Μισθοδοσία, Εκκαθαρίσεις & Ταμείο Εταιρείας",
                    icon: Icons.account_balance_wallet_rounded,
                    color: Colors.indigo,
                    onClick: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GlobalPayrollScreen()),
                    ),
                  ),
                  _JobModuleCard(
                    title: "ΠΡΟΤΥΠΑ ΤΙΜΩΝ",
                    subtitle: "Τιμοκατάλογος & Πρότυπα Τιμών Εργασιών",
                    icon: Icons.style_rounded,
                    color: const Color(0xFFFF9800),
                    onClick: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManagePricesScreen()),
                    ),
                  ),
                  _JobModuleCard(
                    title: "ΑΡΧΕΙΟ ΑΓΟΡΩΝ",
                    subtitle: "Ιστορικό Αγορών Υλικών & Τιμολογίων",
                    icon: Icons.archive_rounded,
                    color: const Color(0xFF2563EB),
                    onClick: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MarketArchiveScreen()),
                    ),
                  ),
                  _JobModuleCard(
                    title: "ΣΥΝΤΑΓΕΣ ΕΡΓΩΝ",
                    subtitle: "Έτοιμες Συνταγές, Αναλύσεις & Υπολογισμοί",
                    icon: Icons.auto_fix_high_rounded,
                    color: Colors.blueAccent,
                    onClick: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const JobRecipesScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }
}

class _JobModuleCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onClick;

  const _JobModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onClick,
  });

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
