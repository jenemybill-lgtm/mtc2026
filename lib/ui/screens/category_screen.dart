import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/ui/calculators/mortar_calculator.dart';
import 'package:mtc2026/ui/calculators/window_calculator.dart';
import 'package:mtc2026/ui/calculators/drywall_calculator.dart';
import 'package:mtc2026/ui/calculators/electrical_calculator.dart';
import 'package:mtc2026/ui/calculators/plumbing_calculator.dart';
import 'package:mtc2026/ui/calculators/painting_calculator.dart';
import 'package:mtc2026/ui/calculators/tiles_calculator.dart';
import 'package:mtc2026/ui/calculators/beton_calculator.dart';
import 'package:mtc2026/ui/calculators/floors_calculator.dart';
import 'package:mtc2026/ui/calculators/metal_calculator.dart';
import 'package:mtc2026/ui/calculators/carpentry_calculator.dart';
import 'package:mtc2026/ui/calculators/engineering_calculator.dart';
import 'package:mtc2026/models/enums.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class CategoryScreen extends StatefulWidget {
  final AppDestinations category;
  final int projectId;

  const CategoryScreen({super.key, required this.category, required this.projectId});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: widget.category.color.withValues(alpha: 0.1),
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, child) {
          final items = provider.currentProjectQuoteItems.where((item) => item.category == widget.category).toList();
          final totalCost = items.fold(0.0, (sum, item) => sum + item.cost);
          final totalPrice = items.fold(0.0, (sum, item) => sum + item.priceForClient);
          final currentMargin = items.isNotEmpty ? items.first.categoryProfitMargin : 20.0;

          return Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : double.infinity),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [widget.category.color.withValues(alpha: 0.12), widget.category.color.withValues(alpha: 0.04)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: widget.category.color.withValues(alpha: 0.2), width: 2),
                        boxShadow: [
                          BoxShadow(color: widget.category.color.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                PremiumHeader(title: "ΣΎΝΟΨΗ ΚΑΤΗΓΟΡΊΑΣ", color: widget.category.color),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: widget.category.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                                  child: Text("$currentMargin% PROFIT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: widget.category.color)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                _CostMiniBadge(label: "ΚΟΣΤΟΣ", amount: totalCost, color: Colors.blueGrey),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [widget.category.color.withValues(alpha: 0.2), widget.category.color.withValues(alpha: 0.05)]),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: widget.category.color.withValues(alpha: 0.2), width: 1.5),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("ΠΕΛΑΤΗΣ (ΤΕΛΙΚΗ)", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: widget.category.color, letterSpacing: 0.5)),
                                        Text("${totalPrice.toStringAsFixed(2)} €", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: widget.category.color, letterSpacing: -0.5)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildCalculatorsBar(),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _QuoteItemCard(
                          item: item,
                          onClick: () => _showAddEditDialog(item: item),
                          onDelete: () => provider.deleteQuoteItem(widget.projectId, int.parse(item.id)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        label: const Text("ΝΕΑ ΕΡΓΑΣΙΑ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildCalculatorsBar() {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    return Container(
      width: double.infinity,
      color: Colors.white,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        constraints: BoxConstraints(maxWidth: isDesktop ? 950 : double.infinity),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.start,
          children: [
            if (widget.category == AppDestinations.WINDOWS) _calcBtn("Υπολογιστής", Icons.calculate_rounded, WindowCalculator(onResult: _handleCalcResult)),
            if (widget.category == AppDestinations.DRYWALL) _calcBtn("Υλικά & Εργασία", Icons.square_rounded, DrywallCalculator(onResult: _handleCalcResult)),
            if (widget.category == AppDestinations.GENERAL || widget.category == AppDestinations.TILES) _calcBtn("Υλικά (Άμμος/Τσιμ.)", Icons.home_work_rounded, MortarCalculator(category: widget.category.name, onResult: _handleCalcResult)),
            if (widget.category == AppDestinations.ELECTRICAL) _calcBtn("Υπολογιστής", Icons.bolt_rounded, ElectricalCalculator(onResult: _handleCalcResult)),
            if (widget.category == AppDestinations.PLUMBING) _calcBtn("Υπολογιστής", Icons.water_drop_rounded, PlumbingCalculator(onResult: _handleCalcResult)),
            if (widget.category == AppDestinations.PAINTING) _calcBtn("Υπολογιστής", Icons.brush_rounded, PaintingCalculator(onResult: _handleCalcResult)),
            if (widget.category == AppDestinations.TILES) _calcBtn("Υπολογιστής", Icons.grid_view_rounded, TilesCalculator(onResult: _handleCalcResult)),
            if (widget.category == AppDestinations.BETON) _calcBtn("Υπολογιστής", Icons.warehouse_rounded, BetonCalculator(onResult: _handleCalcResult)),
            if (widget.category == AppDestinations.FLOORS) _calcBtn("Υπολογιστής", Icons.square_foot_rounded, FloorsCalculator(onResult: _handleCalcResult)),
            if (widget.category == AppDestinations.METAL) _calcBtn("Υπολογιστής", Icons.construction_rounded, MetalCalculator(onResult: _handleCalcResult)),
            if (widget.category == AppDestinations.CARPENTRY) _calcBtn("Υπολογιστής", Icons.kitchen_rounded, CarpentryCalculator(onResult: _handleCalcResult)),
            if (widget.category == AppDestinations.ENGINEERING) _calcBtn("Υπολογιστής", Icons.design_services_rounded, EngineeringCalculator(onResult: _handleCalcResult)),
            _actionBtn("ΠΡΟΤΥΠΑ", Icons.style_rounded, _showPriceTemplatesSheet),
            _actionBtn("ΣΥΝΤΑΓΕΣ (RECIPES)", Icons.auto_fix_high_rounded, _showRecipesSheet),
          ],
        ),
      ),
    );
  }

  void _showRecipesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Consumer<ProjectProvider>(
        builder: (context, provider, child) => FutureBuilder<List<JobRecipe>>(
          future: provider.getJobRecipes(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final recipes = snapshot.data!.where((r) => r.category == widget.category.name).toList();

            if (recipes.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Δεν βρέθηκαν συνταγές για αυτή την κατηγορία.", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("ΚΛΕΙΣΙΜΟ")),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PremiumHeader(title: "ΕΠΙΛΟΓΗ ΣΥΝΤΑΓΗΣ", icon: Icons.auto_fix_high_rounded),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: recipes.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final r = recipes[index];
                        return ListTile(
                          title: Text(r.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                          subtitle: Text("${r.materials.length} υλικά + Εργατικά", style: const TextStyle(fontSize: 11)),
                          trailing: const Icon(Icons.add_circle_outline, color: Colors.blue),
                          onTap: () {
                            Navigator.pop(context);
                            _applyRecipe(r);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _applyRecipe(JobRecipe recipe) {
    final qtyC = TextEditingController(text: "1");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("ΕΦΑΡΜΟΓΗ: ${recipe.name}"),
        content: TextField(
          controller: qtyC,
          decoration: const InputDecoration(labelText: "Ποσότητα (π.χ. τ.μ.)"),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
          ElevatedButton(
            onPressed: () {
              final multiplier = double.tryParse(qtyC.text) ?? 1.0;
              final provider = Provider.of<ProjectProvider>(context, listen: false);

              // 1. Add Materials
              for (var mat in recipe.materials) {
                provider.addQuoteItem(widget.projectId, QuoteItem(
                  category: widget.category,
                  description: mat.name,
                  unit: mat.unit,
                  quantity: (mat.quantityPerUnit * multiplier).toString(),
                  unitPrice: "0", // Handled as cost items
                ));
              }

              // 2. Add Labor
              provider.addQuoteItem(widget.projectId, QuoteItem(
                category: widget.category,
                description: "ΕΡΓΑΤΙΚΑ: ${recipe.name}",
                unit: "τ.μ.",
                quantity: multiplier.toString(),
                unitPrice: recipe.estimatedLabor.toString(),
              ));

              Navigator.pop(context);
            }, 
            child: const Text("ΕΦΑΡΜΟΓΗ"),
          ),
        ],
      ),
    );
  }

  Widget _calcBtn(String label, IconData icon, Widget calculator) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: OutlinedButton.icon(
        onPressed: () => _showCalculator(calculator),
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }

  void _showAddEditDialog({QuoteItem? item, GlobalPriceEntity? template}) {
    showDialog(
      context: context,
      builder: (context) => _AddEditQuoteItemDialog(
        category: widget.category,
        projectId: widget.projectId,
        initialItem: item,
        template: template,
      ),
    );
  }

  void _showPriceTemplatesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return Consumer<ProjectProvider>(
          builder: (context, provider, child) {
            return FutureBuilder<List<GlobalPriceEntity>>(
              future: provider.getGlobalPrices(widget.category.name),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final templates = snapshot.data!;
                if (templates.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Δεν υπάρχουν αποθηκευμένα πρότυπα για αυτήν την κατηγορία.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text("ΚΛΕΙΣΙΜΟ"),
                        ),
                      ],
                    ),
                  );
                }

                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "ΠΡΟΤΥΠΑ ΤΙΜΩΝ - ${widget.category.label}",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: templates.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final template = templates[index];
                              return ListTile(
                                dense: false,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                tileColor: widget.category.color.withValues(alpha: 0.05),
                                leading: Icon(widget.category.icon, color: widget.category.color),
                                title: Text(template.description.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("${template.unit} • ${template.defaultUnitPrice.toStringAsFixed(2)} €", style: const TextStyle(fontSize: 11)),
                                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  _showAddEditDialog(template: template);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showCalculator(Widget calculator) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => calculator,
    );
  }

  void _handleCalcResult(String desc, String qty, String price, String note) {
    final item = QuoteItem(
      category: widget.category,
      description: desc,
      unit: "τ.μ.",
      quantity: qty,
      unitPrice: price,
      internalNote: note,
    );
    Provider.of<ProjectProvider>(context, listen: false).addQuoteItem(widget.projectId, item);
  }
}

class _CostMiniBadge extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _CostMiniBadge({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
          Text("${amount.toStringAsFixed(2)} €", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
        ],
      ),
    );
  }
}

class _QuoteItemCard extends StatelessWidget {
  final QuoteItem item;
  final VoidCallback onClick;
  final VoidCallback onDelete;

  const _QuoteItemCard({required this.item, required this.onClick, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = item.category.color;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.08), color.withValues(alpha: 0.01)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onClick,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.description.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5, color: Color(0xFF1E293B)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.subCategory.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                item.subCategory.toUpperCase(),
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color.withValues(alpha: 0.7)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onDelete, 
                      icon: const Icon(Icons.delete_outline_rounded, size: 18), 
                      style: IconButton.styleFrom(backgroundColor: Colors.red.withValues(alpha: 0.05), foregroundColor: Colors.red)
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${item.quantity} ${item.unit} x ${item.unitPrice}€",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (item.hasVat) _Badge(text: item.showVatToClient ? "+ΦΠΑ" : "ΕΝΣΩΜ.ΦΠΑ", color: Colors.orange),
                              if (item.useCustomMargin) ...[
                                const SizedBox(width: 6),
                                _Badge(text: "${item.customProfitMargin.toInt()}% PROFIT", color: Colors.blue),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withValues(alpha: 0.1)),
                      ),
                      child: Text("${item.cost.toStringAsFixed(2)} €", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 7)),
    );
  }
}

class _AddEditQuoteItemDialog extends StatefulWidget {
  final AppDestinations category;
  final int projectId;
  final QuoteItem? initialItem;
  final GlobalPriceEntity? template;

  const _AddEditQuoteItemDialog({required this.category, required this.projectId, this.initialItem, this.template});

  @override
  State<_AddEditQuoteItemDialog> createState() => _AddEditQuoteItemDialogState();
}

class _AddEditQuoteItemDialogState extends State<_AddEditQuoteItemDialog> {
  late TextEditingController _descController;
  late TextEditingController _subCatController;
  late TextEditingController _qtyController;
  late TextEditingController _unitController;
  late TextEditingController _priceController;
  late bool _hasVat;
  late bool _isVatInclusive;
  late bool _showVatToClient;
  late bool _useCustomMargin;
  late TextEditingController _customMarginController;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.initialItem?.description ?? widget.template?.description ?? "");
    _subCatController = TextEditingController(text: widget.initialItem?.subCategory ?? "");
    _qtyController = TextEditingController(text: widget.initialItem?.quantity ?? "1");
    _unitController = TextEditingController(text: widget.initialItem?.unit ?? widget.template?.unit ?? "τ.μ.");
    _priceController = TextEditingController(text: widget.initialItem?.unitPrice ?? (widget.template?.defaultUnitPrice.toString() ?? ""));
    _hasVat = widget.initialItem?.hasVat ?? false;
    _isVatInclusive = widget.initialItem?.isVatInclusive ?? true;
    _showVatToClient = widget.initialItem?.showVatToClient ?? false;
    _useCustomMargin = widget.initialItem?.useCustomMargin ?? false;
    _customMarginController = TextEditingController(text: widget.initialItem?.customProfitMargin.toString() ?? "20.0");
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.category.color;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 10)),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: PremiumHeader(
                  title: widget.initialItem == null ? "ΝΈΑ ΕΡΓΑΣΊΑ" : "ΕΠΕΞΕΡΓΑΣΊΑ",
                  icon: Icons.add_task_rounded,
                  color: color,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _descController, 
                      decoration: const InputDecoration(labelText: "Περιγραφή Εργασίας", prefixIcon: Icon(Icons.description_outlined))
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _subCatController, 
                      decoration: const InputDecoration(labelText: "Χώρος / Υποκατηγορία", prefixIcon: Icon(Icons.room_outlined))
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _qtyController, decoration: const InputDecoration(labelText: "Ποσότητα", prefixIcon: Icon(Icons.numbers)), keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _unitController, decoration: const InputDecoration(labelText: "Μονάδα"))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _priceController, 
                      decoration: const InputDecoration(labelText: "Τιμή Αγοράς (€)", prefixIcon: Icon(Icons.euro_rounded)), 
                      keyboardType: TextInputType.number
                    ),
                    const SizedBox(height: 20),
                    
                    _sectionHeader("ΟΙΚΟΝΟΜΙΚΕΣ ΡΥΘΜΙΣΕΙΣ", color),
                    
                    CheckboxListTile(
                      title: const Text("Εξατομικευμένο κέρδος (%)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      value: _useCustomMargin,
                      onChanged: (v) => setState(() => _useCustomMargin = v!),
                      contentPadding: EdgeInsets.zero,
                      activeColor: color,
                    ),
                    if (_useCustomMargin)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(controller: _customMarginController, decoration: const InputDecoration(labelText: "Ποσοστό Κέρδους (%)"), keyboardType: TextInputType.number),
                      ),
                    
                    CheckboxListTile(
                      title: const Text("ΦΠΑ 24% στην Αγορά", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      value: _hasVat,
                      onChanged: (v) => setState(() => _hasVat = v!),
                      contentPadding: EdgeInsets.zero,
                      activeColor: color,
                    ),
                    if (_hasVat) ...[
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text("Συμπ.", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              value: true, 
                              groupValue: _isVatInclusive, 
                              onChanged: (v) => setState(() => _isVatInclusive = v!),
                              contentPadding: EdgeInsets.zero,
                              activeColor: color,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text("Επιπλέον", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              value: false, 
                              groupValue: _isVatInclusive, 
                              onChanged: (v) => setState(() => _isVatInclusive = v!),
                              contentPadding: EdgeInsets.zero,
                              activeColor: color,
                            ),
                          ),
                        ],
                      ),
                      CheckboxListTile(
                        title: const Text("Εμφάνιση ΦΠΑ στον Πελάτη", style: TextStyle(fontSize: 11)),
                        value: _showVatToClient,
                        onChanged: (v) => setState(() => _showVatToClient = v!),
                        contentPadding: EdgeInsets.zero,
                        activeColor: color,
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context), 
                        child: Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey.withValues(alpha: 0.6)))
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_descController.text.isEmpty) return;
                          final item = QuoteItem(
                            id: widget.initialItem?.id ?? "",
                            category: widget.category,
                            description: _descController.text,
                            subCategory: _subCatController.text,
                            unit: _unitController.text,
                            quantity: _qtyController.text.isEmpty ? "0" : _qtyController.text,
                            unitPrice: _priceController.text.isEmpty ? "0" : _priceController.text,
                            hasVat: _hasVat,
                            isVatInclusive: _isVatInclusive,
                            showVatToClient: _showVatToClient,
                            useCustomMargin: _useCustomMargin,
                            customProfitMargin: double.tryParse(_customMarginController.text) ?? 20.0,
                          );
                          if (widget.initialItem == null) {
                            Provider.of<ProjectProvider>(context, listen: false).addQuoteItem(widget.projectId, item);
                          } else {
                            Provider.of<ProjectProvider>(context, listen: false).updateQuoteItem(widget.projectId, item);
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(widget.initialItem == null ? "ΠΡΟΣΘΉΚΗ" : "ΕΝΗΜΈΡΩΣΗ", style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(width: 4, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: color.withValues(alpha: 0.1))),
        ],
      ),
    );
  }
}