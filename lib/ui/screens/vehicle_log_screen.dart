import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class VehicleLogScreen extends StatefulWidget {
  const VehicleLogScreen({super.key});

  @override
  State<VehicleLogScreen> createState() => _VehicleLogScreenState();
}

class _VehicleLogScreenState extends State<VehicleLogScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("ΔΙΑΧΕΙΡΙΣΗ ΒΑΝ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () async {
              final v = await provider.getVehicle();
              if (mounted) _showVehicleEditDialog(context, v);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final v = await provider.getVehicle();
          if (mounted) _showAddMaintenanceDialog(context, v.id);
        },
        label: const Text("ΝΕΑ ΣΥΝΤΗΡΗΣΗ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        icon: const Icon(Icons.add_rounded),
      ),
      body: FutureBuilder<VehicleEntity>(
        future: provider.getVehicle(),
        builder: (context, vehicleSnapshot) {
          if (!vehicleSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          final vehicle = vehicleSnapshot.data!;

          return FutureBuilder<List<VehicleMaintenanceEntity>>(
            future: provider.getMaintenance(vehicle.id),
            builder: (context, maintenanceSnapshot) {
              if (!maintenanceSnapshot.hasData) return const Center(child: CircularProgressIndicator());
              final maintenance = maintenanceSnapshot.data!;

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _VehicleInfoCard(vehicle: vehicle),
                  const SizedBox(height: 40),
                  const PremiumHeader(title: "ΙΣΤΟΡΙΚΟ ΣΥΝΤΗΡΗΣΗΣ", color: Colors.blueGrey),
                  const SizedBox(height: 20),
                  if (maintenance.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Δεν υπάρχουν καταγραφές.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))))
                  else
                    ...maintenance.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MaintenanceCard(
                        maintenance: m,
                        onDelete: () => provider.deleteMaintenance(m.id).then((_) => setState(() {})),
                      ),
                    )).toList(),
                  const SizedBox(height: 100),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showVehicleEditDialog(BuildContext context, VehicleEntity vehicle) {
    showDialog(
      context: context,
      builder: (context) => _VehicleEditDialog(
        vehicle: vehicle,
        onConfirm: (v) => Provider.of<ProjectProvider>(context, listen: false).updateVehicle(v).then((_) => setState(() {})),
      ),
    );
  }

  void _showAddMaintenanceDialog(BuildContext context, int vehicleId) {
    showDialog(
      context: context,
      builder: (context) => _AddMaintenanceDialog(
        vehicleId: vehicleId,
        onConfirm: (m, add) => Provider.of<ProjectProvider>(context, listen: false).addMaintenance(m, add).then((_) => setState(() {})),
      ),
    );
  }
}

class _VehicleInfoCard extends StatelessWidget {
  final VehicleEntity vehicle;
  const _VehicleInfoCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isInsWarning = DateTime.fromMillisecondsSinceEpoch(vehicle.insuranceExpiry).difference(now).inDays < 15;
    final isKteoWarning = DateTime.fromMillisecondsSinceEpoch(vehicle.kteoExpiry).difference(now).inDays < 15;

    return PremiumCard(
      accentColor: Colors.blue,
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.blue, Color(0xFF4361EE)]),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 10)],
                ),
                child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B))),
                    Text(vehicle.plateNumber.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blue, fontSize: 13, letterSpacing: 2)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InfoBadge(label: "ΑΣΦΑΛΕΙΑ", date: vehicle.insuranceExpiry, isWarning: isInsWarning),
              _InfoBadge(label: "ΚΤΕΟ", date: vehicle.kteoExpiry, isWarning: isKteoWarning),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(height: 1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _mileStat("ΤΡΕΧΟΝΤΑ ΧΛΜ", vehicle.currentMileage),
              _mileStat("ΤΕΛ. SERVICE", vehicle.lastServiceMileage, align: CrossAxisAlignment.end),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mileStat(String label, int val, {CrossAxisAlignment align = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text("${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} km", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B))),
      ],
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final int date;
  final bool isWarning;

  const _InfoBadge({required this.label, required this.date, required this.isWarning});

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? Colors.red : Colors.blue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.12)),
          ),
          child: Text(DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(date)), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: color)),
        ),
      ],
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  final VehicleMaintenanceEntity maintenance;
  final VoidCallback onDelete;

  const _MaintenanceCard({required this.maintenance, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.withValues(alpha: 0.08), Colors.blue.withValues(alpha: 0.01)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.12)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.build_rounded, color: Colors.blue, size: 20),
        ),
        title: Text(maintenance.description.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF1E293B))),
        subtitle: Text("${DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(maintenance.date))} • ${maintenance.mileage} km", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("${maintenance.cost.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blue, fontSize: 14)),
            const SizedBox(width: 8),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.black12)),
          ],
        ),
      ),
    );
  }
}

class _VehicleEditDialog extends StatefulWidget {
  final VehicleEntity vehicle;
  final Function(VehicleEntity) onConfirm;

  const _VehicleEditDialog({required this.vehicle, required this.onConfirm});

  @override
  State<_VehicleEditDialog> createState() => _VehicleEditDialogState();
}

class _VehicleEditDialogState extends State<_VehicleEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _plateController;
  late TextEditingController _mileageController;
  late TextEditingController _lastServiceController;
  late int _insExp;
  late int _kteoExp;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vehicle.name);
    _plateController = TextEditingController(text: widget.vehicle.plateNumber);
    _mileageController = TextEditingController(text: widget.vehicle.currentMileage.toString());
    _lastServiceController = TextEditingController(text: widget.vehicle.lastServiceMileage.toString());
    _insExp = widget.vehicle.insuranceExpiry;
    _kteoExp = widget.vehicle.kteoExpiry;
  }

  @override
  Widget build(BuildContext context) {
    const color = Colors.blue;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30)],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
                child: PremiumHeader(title: "ΣΤΟΙΧΕΙΑ ΟΧΗΜΑΤΟΣ", icon: Icons.local_shipping_rounded, color: color),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Όνομα Βαν", prefixIcon: Icon(Icons.badge_outlined))),
                    const SizedBox(height: 12),
                    TextField(controller: _plateController, decoration: const InputDecoration(labelText: "Πινακίδα", prefixIcon: Icon(Icons.tag))),
                    const SizedBox(height: 12),
                    TextField(controller: _mileageController, decoration: const InputDecoration(labelText: "Χιλιόμετρα", prefixIcon: Icon(Icons.speed_rounded)), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(controller: _lastServiceController, decoration: const InputDecoration(labelText: "Τελ. Service (km)", prefixIcon: Icon(Icons.build_circle_outlined)), keyboardType: TextInputType.number),
                    const SizedBox(height: 20),
                    _sectionLabel("ΗΜΕΡΟΜΗΝΙΕΣ ΕΛΕΓΧΟΥ"),
                    const SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      tileColor: Colors.blue.withValues(alpha: 0.05),
                      leading: const Icon(Icons.security_rounded, color: Colors.blue),
                      title: const Text("Λήξη Ασφάλειας", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(_insExp)), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                      onTap: () async {
                        final date = await showDatePicker(context: context, initialDate: DateTime.fromMillisecondsSinceEpoch(_insExp), firstDate: DateTime(2000), lastDate: DateTime(2100));
                        if (date != null) setState(() => _insExp = date.millisecondsSinceEpoch);
                      },
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      tileColor: Colors.blue.withValues(alpha: 0.05),
                      leading: const Icon(Icons.fact_check_rounded, color: Colors.blue),
                      title: const Text("Λήξη ΚΤΕΟ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(_kteoExp)), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                      onTap: () async {
                        final date = await showDatePicker(context: context, initialDate: DateTime.fromMillisecondsSinceEpoch(_kteoExp), firstDate: DateTime(2000), lastDate: DateTime(2100));
                        if (date != null) setState(() => _kteoExp = date.millisecondsSinceEpoch);
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey)))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onConfirm(widget.vehicle.copyWith(
                            name: _nameController.text,
                            plateNumber: _plateController.text,
                            currentMileage: int.tryParse(_mileageController.text) ?? 0,
                            lastServiceMileage: int.tryParse(_lastServiceController.text) ?? 0,
                            insuranceExpiry: _insExp,
                            kteoExpiry: _kteoExp,
                          ));
                          Navigator.pop(context);
                        },
                        child: const Text("ΑΠΟΘΗΚΕΥΣΗ", style: TextStyle(fontWeight: FontWeight.w900)),
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
  Widget _sectionLabel(String l) => Row(children: [Text(l, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)), const SizedBox(width: 8), const Expanded(child: Divider())]);
}

class _AddMaintenanceDialog extends StatefulWidget {
  final int vehicleId;
  final Function(VehicleMaintenanceEntity, bool) onConfirm;

  const _AddMaintenanceDialog({required this.vehicleId, required this.onConfirm});

  @override
  State<_AddMaintenanceDialog> createState() => _AddMaintenanceDialogState();
}

class _AddMaintenanceDialogState extends State<_AddMaintenanceDialog> {
  final _descController = TextEditingController();
  final _costController = TextEditingController();
  final _mileageController = TextEditingController();
  bool _addExpense = true;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF10B981);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
              child: PremiumHeader(title: "ΝΕΑ ΣΥΝΤΗΡΗΣΗ", icon: Icons.build_circle_rounded, color: color),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(controller: _descController, decoration: const InputDecoration(labelText: "Περιγραφή Εργασιών", prefixIcon: Icon(Icons.description_outlined))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _costController, decoration: const InputDecoration(labelText: "Κόστος (€)", prefixIcon: Icon(Icons.euro_rounded)), keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _mileageController, decoration: const InputDecoration(labelText: "Χιλιόμετρα", prefixIcon: Icon(Icons.speed_rounded)), keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                    child: CheckboxListTile(
                      title: const Text("Προσθήκη στα Έξοδα Εταιρείας", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      value: _addExpense,
                      onChanged: (v) => setState(() => _addExpense = v!),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      activeColor: color,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey)))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_descController.text.isNotEmpty) {
                          widget.onConfirm(VehicleMaintenanceEntity(
                            vehicleId: widget.vehicleId,
                            description: _descController.text,
                            cost: double.tryParse(_costController.text) ?? 0.0,
                            mileage: int.tryParse(_mileageController.text) ?? 0,
                            date: DateTime.now().millisecondsSinceEpoch,
                          ), _addExpense);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: color),
                      child: const Text("ΚΑΤΑΧΩΡΗΣΗ", style: TextStyle(fontWeight: FontWeight.w900)),
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
