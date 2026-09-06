import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/models/enums.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/utils/pdf_generator.dart';
import 'package:mtc2026/ui/screens/summary_screen.dart';
import 'package:mtc2026/ui/screens/category_screen.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class QuoteCategoriesScreen extends StatefulWidget {
  final Project project;

  const QuoteCategoriesScreen({super.key, required this.project});

  @override
  State<QuoteCategoriesScreen> createState() => _QuoteCategoriesScreenState();
}

class _QuoteCategoriesScreenState extends State<QuoteCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProjectProvider>(context, listen: false).fetchProjectData(widget.project.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final items = provider.currentProjectQuoteItems;
        final totalAmount = provider.totalQuoteRevenue;

        return Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : double.infinity),
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                PremiumCard(
                  accentColor: Colors.blue,
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PremiumHeader(title: "ΣΥΝΟΛΙΚΉ ΑΞΊΑ ΠΡΟΣΦΟΡΆΣ", color: Colors.blue),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "${totalAmount.toStringAsFixed(2)} €",
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: -1),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton.filledTonal(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => SummaryScreen(project: widget.project)));
                                },
                                icon: const Icon(Icons.analytics_outlined),
                                style: IconButton.styleFrom(backgroundColor: Colors.blue.withValues(alpha: 0.1), foregroundColor: Colors.blue),
                              ),
                              const SizedBox(width: 12),
                              IconButton.filledTonal(
                                onPressed: () {
                                  bool showTotals = true;
                                  bool showPrices = true;
                                  bool showTasks = false;
                                  showDialog(
                                    context: context,
                                    builder: (context) => StatefulBuilder(
                                      builder: (context, setDialogState) => AlertDialog(
                                        title: const Text("ΕΠΙΛΟΓΕΣ ΕΚΤΥΠΩΣΗΣ ΠΡΟΣΦΟΡΑΣ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CheckboxListTile(
                                              title: const Text("Εμφάνιση συνόλων ανά κατηγορία", style: TextStyle(fontSize: 13)),
                                              value: showTotals,
                                              onChanged: (v) => setDialogState(() => showTotals = v ?? true),
                                            ),
                                            CheckboxListTile(
                                              title: const Text("Εμφάνιση επιμέρους εργασιών", style: TextStyle(fontSize: 13)),
                                              value: showTasks,
                                              onChanged: (v) => setDialogState(() => showTasks = v ?? true),
                                            ),
                                            CheckboxListTile(
                                              title: const Text("Εμφάνιση τιμών ανά εργασία", style: TextStyle(fontSize: 13)),
                                              value: showPrices,
                                              onChanged: (v) => setDialogState(() => showPrices = v ?? true),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
                                          ElevatedButton(
                                            onPressed: () async {
                                              Navigator.pop(context);
                                              
                                              // Add a tiny delay to allow the dialog to close before generating PDF
                                              await Future.delayed(const Duration(milliseconds: 100));
                                              
                                              PdfGenerator.generateAndShareQuote(
                                                projectName: widget.project.name,
                                                items: items,
                                                settings: provider.settings,
                                                showCategoryTotals: showTotals,
                                                showItemPrices: showPrices,
                                                showItemizedTasks: showTasks,
                                              );
                                            },
                                            child: const Text("ΕΚΔΟΣΗ PDF"),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.picture_as_pdf_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                                  foregroundColor: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const PremiumHeader(title: "ΚΑΤΗΓΟΡΙΕΣ ΕΡΓΑΣΙΩΝ", color: Colors.blueGrey),
                const SizedBox(height: 24),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isDesktop ? 1.6 : 1.1,
                  ),
                  itemCount: AppDestinations.values.length,
                  itemBuilder: (context, index) {
                    final category = AppDestinations.values[index];
                    final hasItems = items.any((item) => item.category == category);
                    return _CategoryCard(
                      category: category,
                      hasItems: hasItems,
                      onClick: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryScreen(
                              category: category,
                              projectId: widget.project.id,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final AppDestinations category;
  final bool hasItems;
  final VoidCallback onClick;

  const _CategoryCard({required this.category, required this.hasItems, required this.onClick});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [category.color.withValues(alpha: 0.12), category.color.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: category.color.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(color: category.color.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onClick,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [category.color, category.color.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: category.color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Icon(category.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    category.label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (hasItems) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: category.color, borderRadius: BorderRadius.circular(6)),
                      child: const Text("ΕΝΕΡΓΟ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 7, letterSpacing: 1)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
