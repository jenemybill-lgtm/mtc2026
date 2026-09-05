import 'package:flutter/material.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';
import 'package:mtc2026/ui/screens/manage_prices_screen.dart';
import 'package:mtc2026/ui/screens/vehicle_log_screen.dart';
import 'package:mtc2026/ui/screens/global_calendar_screen.dart';
import 'package:mtc2026/ui/screens/weekly_payroll_screen.dart';
import 'package:mtc2026/ui/screens/location_selector_screen.dart';
import 'package:mtc2026/ui/screens/tool_category_picker_screen.dart';
import 'package:mtc2026/ui/screens/partners_screen.dart';
import 'package:mtc2026/ui/screens/clients_screen.dart';
import 'package:mtc2026/ui/screens/company_expenses_screen.dart';
import 'package:mtc2026/ui/screens/market_archive_screen.dart';
import 'package:mtc2026/ui/screens/job_recipes_screen.dart';
import 'package:mtc2026/ui/screens/global_payroll_screen.dart';
import 'package:mtc2026/ui/screens/managers_screen.dart';

class CompanyHubScreen extends StatefulWidget {
  const CompanyHubScreen({super.key});

  @override
  State<CompanyHubScreen> createState() => _CompanyHubScreenState();
}

class _CompanyHubScreenState extends State<CompanyHubScreen> {
  String _viewMode = "MAIN";

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return WillPopScope(
      onWillPop: () async {
        if (_viewMode != "MAIN") {
          setState(() => _viewMode = "MAIN");
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: Text(
            _viewMode == "MATERIALS"
                ? "ΔΙΑΧΕΙΡΙΣΗ ΥΛΙΚΟΥ"
                : _viewMode == "JOBS"
                    ? "ΔΙΑΧΕΙΡΙΣΗ ΕΡΓΑΣΙΩΝ"
                    : "ΚΕΝΤΡΟ ΕΛΕΓΧΟΥ",
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (_viewMode == "MAIN") {
                Navigator.pop(context);
              } else {
                setState(() => _viewMode = "MAIN");
              }
            },
          ),
        ),
        body: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
            child: _buildBody(isDesktop),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDesktop) {
    switch (_viewMode) {
      case "MATERIALS":
        return _buildMaterialsGrid(isDesktop);
      case "JOBS":
        return _buildJobsGrid(isDesktop);
      default:
        return _buildMainOptions(isDesktop);
    }
  }

  Widget _buildMainOptions(bool isDesktop) {
    return ListView(
      padding: EdgeInsets.all(isDesktop ? 40.0 : 24.0),
      children: [
        const SizedBox(height: 20),
        _PremiumHubCategoryCard(
          label: "ΔΙΑΧΕΙΡΙΣΗ ΥΛΙΚΟΥ",
          subtitle: "Αποθήκη, Βαν, Εργαλεία & Οχήματα",
          icon: Icons.inventory_2_rounded,
          color: const Color(0xFF4361EE),
          onClick: () => setState(() => _viewMode = "MATERIALS"),
          isDesktop: isDesktop,
        ),
        const SizedBox(height: 24),
        _PremiumHubCategoryCard(
          label: "ΔΙΑΧΕΙΡΙΣΗ ΕΡΓΑΣΙΩΝ",
          subtitle: "Πελάτες, Συνεργάτες, Παρουσιολόγιο & Ταμείο",
          icon: Icons.engineering_rounded,
          color: const Color(0xFF7209B7),
          onClick: () => setState(() => _viewMode = "JOBS"),
          isDesktop: isDesktop,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildMaterialsGrid(bool isDesktop) {
    final hubs = [
      _HomeHub(label: "ΑΠΟΘΗΚΗ", icon: Icons.warehouse_rounded, id: "LOCATION_WAREHOUSE", color: const Color(0xFF3A0CA3)),
      _HomeHub(label: "ΒΑΝ / ΑΜΑΞΙ", icon: Icons.local_shipping_rounded, id: "LOCATION_VAN", color: const Color(0xFF4361EE)),
      _HomeHub(label: "ΔΙΑΧΕΙΡΙΣΗ ΒΑΝ", icon: Icons.directions_car_rounded, id: "VEHICLE_LOG", color: const Color(0xFF10B981)),
      _HomeHub(label: "ΣΥΝΟΛΟ ΕΡΓΑΛΕΙΩΝ", icon: Icons.home_repair_service_rounded, id: "TOTAL_TOOLS_PICKER", color: const Color(0xFF7209B7)),
      _HomeHub(label: "ΣΥΝΕΡΓΕΙΟ", icon: Icons.build_rounded, id: "REPAIR_TOOLS", color: const Color(0xFFF72585)),
    ];
    return _HubGrid(hubs: hubs, isDesktop: isDesktop);
  }

  Widget _buildJobsGrid(bool isDesktop) {
    final hubs = [
      _HomeHub(label: "ΗΜΕΡΟΛΟΓΙΟ", icon: Icons.date_range_rounded, id: "CALENDAR", color: const Color(0xFF4361EE)),
      _HomeHub(label: "ΣΥΝΕΡΓΑΤΕΣ", icon: Icons.groups_rounded, id: "PARTNERS", color: const Color(0xFF7209B7)),
      _HomeHub(label: "ΠΕΛΑΤΕΣ", icon: Icons.person_search_rounded, id: "CLIENTS", color: const Color(0xFF4CC9F0)),
      _HomeHub(label: "ΚΕΝΤΡΙΚΟ ΤΑΜΕΙΟ", icon: Icons.account_balance_wallet_rounded, id: "GLOBAL_PAYROLL", color: Colors.indigo),
      _HomeHub(label: "ΠΑΡΟΥΣΙΟΛΟΓΙΟ", icon: Icons.price_check_rounded, id: "WEEKLY_PAYROLL", color: const Color(0xFF38B000)),
      _HomeHub(label: "ΟΙΚΟΝΟΜΙΚΑ", icon: Icons.monetization_on_rounded, id: "ECONOMICS", color: const Color(0xFFB5179E)),
      _HomeHub(label: "ΠΡΟΤΥΠΑ ΤΙΜΩΝ", icon: Icons.style_rounded, id: "MANAGE_PRICES", color: const Color(0xFFFF9800)),
      _HomeHub(label: "ΑΡΧΕΙΟ ΑΓΟΡΩΝ", icon: Icons.archive_rounded, id: "MARKET_ARCHIVE", color: const Color(0xFF4361EE)),
      _HomeHub(label: "ΣΥΝΤΑΓΕΣ ΕΡΓΩΝ", icon: Icons.auto_fix_high_rounded, id: "JOB_RECIPES", color: Colors.blueAccent),
      _HomeHub(label: "ΥΠΕΥΘΥΝΟΙ ΕΡΓΩΝ", icon: Icons.engineering_rounded, id: "MANAGERS", color: Colors.teal),
    ];
    return _HubGrid(hubs: hubs, isDesktop: isDesktop);
  }
}

class _PremiumHubCategoryCard extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onClick;
  final bool isDesktop;

  const _PremiumHubCategoryCard({required this.label, required this.subtitle, required this.icon, required this.color, required this.onClick, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isDesktop ? 160 : 130,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 10)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onClick,
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 28),
            child: Row(
              children: [
                Container(
                  width: isDesktop ? 80 : 64, 
                  height: isDesktop ? 80 : 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 6))],
                  ),
                  child: Icon(icon, color: Colors.white, size: isDesktop ? 40 : 30),
                ),
                SizedBox(width: isDesktop ? 40 : 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label, 
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: isDesktop ? 22 : 17, letterSpacing: 0.5, color: const Color(0xFF1E293B))
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle, 
                        style: TextStyle(color: Colors.grey.withValues(alpha: 0.8), fontSize: isDesktop ? 13 : 11, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: color.withValues(alpha: 0.2), size: isDesktop ? 24 : 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHub {
  final String label;
  final IconData icon;
  final String id;
  final Color color;
  _HomeHub({required this.label, required this.icon, required this.id, required this.color});
}

class _HubGrid extends StatelessWidget {
  final List<_HomeHub> hubs;
  final bool isDesktop;
  const _HubGrid({required this.hubs, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(isDesktop ? 40 : 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 3 : 2,
        crossAxisSpacing: isDesktop ? 32 : 16,
        mainAxisSpacing: isDesktop ? 32 : 16,
        childAspectRatio: isDesktop ? 1.3 : 1.1,
      ),
      itemCount: hubs.length,
      itemBuilder: (context, index) {
        final hub = hubs[index];
        return _PremiumHubCard(
          hub: hub,
          isDesktop: isDesktop,
          onClick: () {
            if (hub.id == "PARTNERS") Navigator.push(context, MaterialPageRoute(builder: (context) => const PartnersScreen()));
            else if (hub.id == "CLIENTS") Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientsScreen()));
            else if (hub.id == "GLOBAL_PAYROLL") Navigator.push(context, MaterialPageRoute(builder: (context) => const GlobalPayrollScreen()));
            else if (hub.id == "LOCATION_WAREHOUSE") Navigator.push(context, MaterialPageRoute(builder: (context) => const LocationSelectorScreen(locationName: "ΑΠΟΘΗΚΗ", locationType: "WAREHOUSE")));
            else if (hub.id == "LOCATION_VAN") Navigator.push(context, MaterialPageRoute(builder: (context) => const LocationSelectorScreen(locationName: "ΒΑΝ / ΑΜΑΞΙ", locationType: "VAN")));
            else if (hub.id == "VEHICLE_LOG") Navigator.push(context, MaterialPageRoute(builder: (context) => const VehicleLogScreen()));
            else if (hub.id == "TOTAL_TOOLS_PICKER") Navigator.push(context, MaterialPageRoute(builder: (context) => const ToolCategoryPickerScreen(title: "ΣΥΝΟΛΟ ΕΡΓΑΛΕΙΩΝ", locationType: "TOTAL")));
            else if (hub.id == "REPAIR_TOOLS") Navigator.push(context, MaterialPageRoute(builder: (context) => const ToolCategoryPickerScreen(title: "ΣΥΝΕΡΓΕΙΟ ΕΠΙΣΚΕΥΩΝ", locationType: "REPAIR")));
            else if (hub.id == "WEEKLY_PAYROLL") Navigator.push(context, MaterialPageRoute(builder: (context) => const WeeklyPayrollScreen()));
            else if (hub.id == "CALENDAR") Navigator.push(context, MaterialPageRoute(builder: (context) => const GlobalCalendarScreen()));
            else if (hub.id == "MANAGE_PRICES") Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagePricesScreen()));
            else if (hub.id == "ECONOMICS") Navigator.push(context, MaterialPageRoute(builder: (context) => const CompanyExpensesScreen()));
            else if (hub.id == "MARKET_ARCHIVE") Navigator.push(context, MaterialPageRoute(builder: (context) => const MarketArchiveScreen()));
            else if (hub.id == "JOB_RECIPES") Navigator.push(context, MaterialPageRoute(builder: (context) => const JobRecipesScreen()));
            else if (hub.id == "MANAGERS") Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagersScreen()));
          },
        );
      },
    );
  }
}

class _PremiumHubCard extends StatelessWidget {
  final _HomeHub hub;
  final bool isDesktop;
  final VoidCallback onClick;

  const _PremiumHubCard({required this.hub, required this.isDesktop, required this.onClick});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [hub.color.withValues(alpha: 0.1), hub.color.withValues(alpha: 0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: hub.color.withValues(alpha: 0.12), width: 1.5),
        boxShadow: [
          BoxShadow(color: hub.color.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onClick,
          borderRadius: BorderRadius.circular(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isDesktop ? 76 : 56, 
                height: isDesktop ? 76 : 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [hub.color, hub.color.withValues(alpha: 0.7)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: hub.color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                ),
                child: Icon(hub.icon, color: Colors.white, size: isDesktop ? 36 : 26),
              ),
              SizedBox(height: isDesktop ? 20 : 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    hub.label, 
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: isDesktop ? 14 : 11, color: const Color(0xFF1E293B), letterSpacing: 0.5), 
                    textAlign: TextAlign.center
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
