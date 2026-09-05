import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/models/enums.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';
import 'package:mtc2026/utils/pdf_generator.dart';
import 'package:mtc2026/utils/excel_exporter.dart';

class MarketArchiveScreen extends StatefulWidget {
  const MarketArchiveScreen({super.key});

  @override
  State<MarketArchiveScreen> createState() => _MarketArchiveScreenState();
}

class _MarketArchiveScreenState extends State<MarketArchiveScreen> {
  String _searchQuery = "";
  String _selectedCategory = "ALL";

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final categoryTabs = ['ALL', ...AppDestinations.values.map((d) => d.name)];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          "ΑΡΧΕΙΟ ΑΓΟΡΩΝ & ΤΙΜΩΝ",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
        backgroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.settings_suggest_rounded,
                color: Colors.blue,
                size: 20,
              ),
              tooltip: "Διαχείριση Υποκατηγοριών",
              onPressed: () =>
                  _showManageSubcategoriesDialog(context, provider),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
              onPressed: () async {
                final items = await provider.getMarketArchive();
                if (context.mounted) {
                  PdfGenerator.generateAndShareMarketArchive(
                    items: items,
                    settings: provider.settings,
                  );
                }
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.file_download_rounded,
                color: Colors.green,
                size: 20,
              ),
              onPressed: () async {
                final items = await provider.getMarketArchive();
                ExcelExporter.exportMarketArchive(items);
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntryDialog(context, provider),
        label: const Text(
          "ΝΕΑ ΚΑΤΑΧΩΡΗΣΗ",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        icon: const Icon(Icons.add_shopping_cart_rounded),
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          _buildCategoryTabs(categoryTabs),
          Expanded(
            child: FutureBuilder<List<MarketArchiveItem>>(
              future: provider.getMarketArchive(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data ?? [];
                final filtered = items
                    .where(
                      (i) =>
                          i.name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          i.supplier.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ),
                    )
                    .toList();

                final categoryFiltered = _filterBySelectedCategory(filtered);

                if (categoryFiltered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_rounded,
                          size: 64,
                          color: Colors.blueGrey.withValues(alpha: 0.1),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Δεν βρέθηκαν καταχωρήσεις",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final grouped = _groupItems(categoryFiltered);

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final category = grouped.keys.elementAt(index);
                    final subGroups = grouped[category]!;
                    final dest = AppDestinations.values.firstWhere(
                      (d) => d.name == category,
                      orElse: () => AppDestinations.GENERAL,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 32, 8, 16),
                          child: PremiumHeader(
                            title: dest.label,
                            icon: dest.icon,
                            color: dest.color,
                          ),
                        ),
                        ...subGroups.entries.map((subEntry) {
                          final subCatName = subEntry.key;
                          final nameGroups = subEntry.value;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  8,
                                  12,
                                ),
                                child: Text(
                                  subCatName.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    color: dest.color.withValues(alpha: 0.7),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              ...nameGroups.entries.map((nameEntry) {
                                final itemName = nameEntry.key;
                                final records = nameEntry.value;
                                return _ItemPriceGroupCard(
                                  itemName: itemName,
                                  records: records,
                                  onAddPrice: () => _showAddEntryDialog(
                                    context,
                                    provider,
                                    prefill: records.first,
                                  ),
                                  onEdit: (item) => _showAddEntryDialog(
                                    context,
                                    provider,
                                    item: item,
                                  ),
                                  onDelete: (item) async {
                                    await provider.deleteMarketArchiveItem(
                                      item.id,
                                    );
                                    if (mounted) setState(() {});
                                  },
                                );
                              }),
                            ],
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      color: Colors.white,
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: "Αναζήτηση υλικού ή προμηθευτή...",
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.blueGrey),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(List<String> categoryTabs) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: categoryTabs.map((tab) {
          final isAll = tab == 'ALL';
          final AppDestinations destination = isAll
              ? AppDestinations.GENERAL
              : AppDestinations.values.firstWhere(
                  (d) => d.name == tab,
                  orElse: () => AppDestinations.GENERAL,
                );
          final label = isAll ? 'ΟΛΑ' : destination.label;
          final color = isAll ? Colors.indigo : destination.color;
          final isSelected = _selectedCategory == tab;

          return Material(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _selectedCategory = tab),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? color.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.06),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAll ? Icons.grid_view_rounded : destination.icon,
                      size: 16,
                      color: isSelected ? color : Colors.blueGrey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? color : Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  }

  List<MarketArchiveItem> _filterBySelectedCategory(
    List<MarketArchiveItem> items,
  ) {
    if (_selectedCategory == 'ALL') {
      return items;
    }
    return items.where((item) => item.category == _selectedCategory).toList();
  }

  Map<String, Map<String, Map<String, List<MarketArchiveItem>>>> _groupItems(
    List<MarketArchiveItem> items,
  ) {
    final Map<String, Map<String, Map<String, List<MarketArchiveItem>>>>
    groups = {};
    for (var item in items) {
      groups.putIfAbsent(item.category, () => {});
      final catGroup = groups[item.category]!;

      final subCat = item.subCategory.trim().toUpperCase();
      catGroup.putIfAbsent(subCat, () => {});

      final nameGroup = catGroup[subCat]!;
      final normalizedName = item.name.trim().toUpperCase();
      nameGroup.putIfAbsent(normalizedName, () => []).add(item);
    }
    return groups;
  }

  void _showAddEntryDialog(
    BuildContext context,
    ProjectProvider provider, {
    MarketArchiveItem? item,
    MarketArchiveItem? prefill,
  }) {
    final nameController = TextEditingController(
      text: item?.name ?? prefill?.name ?? "",
    );
    final supplierController = TextEditingController(
      text: item?.supplier ?? "",
    );
    final priceController = TextEditingController(
      text: item?.price != null ? item!.price.toString() : "",
    );
    final unitController = TextEditingController(
      text: item?.unit ?? prefill?.unit ?? "τμ",
    );
    String? selectedCategory = item?.category ?? prefill?.category;
    String selectedType = item?.type ?? prefill?.type ?? "MATERIAL";
    String? selectedSubCat = item?.subCategory ?? prefill?.subCategory;
    bool hasVat = item?.hasVat ?? false;
    DateTime selectedDate = DateTime.fromMillisecondsSinceEpoch(
      item?.dateAdded ??
          prefill?.dateAdded ??
          DateTime.now().millisecondsSinceEpoch,
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          title: PremiumHeader(
            title: item == null ? "ΝΕΑ ΚΑΤΑΧΩΡΗΣΗ" : "ΕΠΕΞΕΡΓΑΣΙΑ",
            icon: Icons.add_business_rounded,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: "MATERIAL", label: Text("Υλικό")),
                    ButtonSegment(value: "TOOL", label: Text("Εργαλείο")),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (s) =>
                      setState(() => selectedType = s.first),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) setState(() => selectedDate = date);
                        },
                        icon: const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                        ),
                        label: Text(
                          DateFormat('dd/MM/yyyy').format(selectedDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Όνομα είδους (π.χ. Τσιμέντο)",
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue:
                            provider.marketSubCategories.contains(
                              selectedSubCat,
                            )
                            ? selectedSubCat
                            : null,
                        decoration: const InputDecoration(
                          labelText: "Υποκατηγορία",
                        ),
                        items: provider.marketSubCategories
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => selectedSubCat = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () {
                        _showNewSubcategoryInline(context, provider, (newCat) {
                          setState(() => selectedSubCat = newCat);
                        });
                      },
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: "Κύρια Κατηγορία",
                  ),
                  items: AppDestinations.values
                      .map(
                        (d) => DropdownMenuItem(
                          value: d.name,
                          child: Text(d.label),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => selectedCategory = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: supplierController,
                  decoration: const InputDecoration(
                    labelText: "Προμηθευτής / Κατάστημα",
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: "Τιμή Αγοράς",
                          prefixIcon: Icon(Icons.euro_rounded),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: unitController,
                        decoration: const InputDecoration(labelText: "Μονάδα"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: CheckboxListTile(
                    title: const Text(
                      "Η τιμή περιλαμβάνει ΦΠΑ 24%",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    value: hasVat,
                    onChanged: (v) => setState(() => hasVat = v!),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "ΑΚΥΡΟ",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    selectedCategory != null) {
                  final newItem = MarketArchiveItem(
                    id: item?.id ?? 0,
                    name: nameController.text,
                    category: selectedCategory!,
                    subCategory: selectedSubCat ?? "ΓΕΝΙΚΑ",
                    type: selectedType,
                    supplier: supplierController.text,
                    price: double.tryParse(priceController.text) ?? 0.0,
                    unit: unitController.text,
                    hasVat: hasVat,
                    dateAdded: selectedDate.millisecondsSinceEpoch,
                  );

                  try {
                    if (item == null) {
                      await provider.addMarketArchiveItem(newItem);
                    } else {
                      await provider.updateMarketArchiveItem(newItem);
                    }
                    await provider.fetchProjects();
                    if (context.mounted) Navigator.pop(context);
                    if (mounted) setState(() {});
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Σφάλμα αποθήκευσης: $e")),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Συμπληρώστε όνομα και κατηγορία"),
                    ),
                  );
                }
              },
              child: const Text(
                "ΑΠΟΘΗΚΕΥΣΗ",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewSubcategoryInline(
    BuildContext context,
    ProjectProvider provider,
    Function(String) onAdded,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "ΝΕΑ ΥΠΟΚΑΤΗΓΟΡΙΑ",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Όνομα (π.χ. ΜΟΝΩΤΙΚΑ)"),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ΑΚΥΡΟ"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final name = controller.text.trim().toUpperCase();
                await provider.addMarketSubCategory(name);
                onAdded(name);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("ΠΡΟΣΘΗΚΗ"),
          ),
        ],
      ),
    );
  }

  void _showManageSubcategoriesDialog(
    BuildContext context,
    ProjectProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => Consumer<ProjectProvider>(
        builder: (context, provider, _) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: const PremiumHeader(
            title: "ΔΙΑΧΕΙΡΙΣΗ ΥΠΟΚΑΤΗΓΟΡΙΩΝ",
            icon: Icons.settings_suggest_rounded,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Αυτές οι υποκατηγορίες εμφανίζονται ως επιλογές κατά την καταχώρηση νέων υλικών.",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: provider.marketSubCategories.length,
                    itemBuilder: (context, index) {
                      final cat = provider.marketSubCategories[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          cat,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          onPressed: () =>
                              provider.deleteMarketSubCategory(cat),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showNewSubcategoryInline(context, provider, (_) {}),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text("ΠΡΟΣΘΗΚΗ ΝΕΑΣ"),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "ΚΛΕΙΣΙΜΟ",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemPriceGroupCard extends StatelessWidget {
  final String itemName;
  final List<MarketArchiveItem> records;
  final VoidCallback onAddPrice;
  final Function(MarketArchiveItem) onEdit;
  final Function(MarketArchiveItem) onDelete;

  const _ItemPriceGroupCard({
    required this.itemName,
    required this.records,
    required this.onAddPrice,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final type = records.first.type;
    final color = type == "MATERIAL" ? Colors.blue : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    type == "MATERIAL"
                        ? Icons.inventory_2_rounded
                        : Icons.build_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    itemName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onAddPrice,
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: Colors.blue,
                  ),
                  tooltip: "Προσθήκη νέου προμηθευτή",
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(height: 1, color: color.withValues(alpha: 0.1)),
          ),
          ...records.map(
            (item) => _PriceRecordLine(
              item: item,
              onEdit: () => onEdit(item),
              onDelete: () => onDelete(item),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRecordLine extends StatelessWidget {
  final MarketArchiveItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PriceRecordLine({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.supplier.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd/MM/yy').format(
                      DateTime.fromMillisecondsSinceEpoch(item.dateAdded),
                    ),
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "${item.price.toStringAsFixed(2)} €",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Text(
                    "ανά ${item.unit}",
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (item.hasVat ? Colors.green : Colors.blueGrey)
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.hasVat ? "ΜΕ ΦΠΑ" : "+ ΦΠΑ",
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        color: item.hasVat ? Colors.green : Colors.blueGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: Colors.black12,
              ),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
