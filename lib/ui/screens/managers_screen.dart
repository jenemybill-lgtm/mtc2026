import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class ManagersScreen extends StatelessWidget {
  const ManagersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final managers = provider.managers;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("ΔΙΑΧΕΙΡΙΣΗ ΥΠΕΥΘΥΝΩΝ ΕΡΓΩΝ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditManagerDialog(context),
        label: const Text("ΝΕΟΣ ΥΠΕΥΘΥΝΟΣ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        icon: const Icon(Icons.person_add_rounded),
      ),
      body: managers.isEmpty
          ? const Center(child: Text("Δεν βρέθηκαν υπεύθυνοι έργων", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: managers.length,
              itemBuilder: (context, index) {
                final m = managers[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.engineering_rounded, color: Colors.blue),
                    ),
                    title: Text(m.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B))),
                    subtitle: Text("PIN: ${m.pin}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: Colors.blue, size: 20),
                          onPressed: () => _showAddEditManagerDialog(context, manager: m),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                          onPressed: () => provider.deleteManager(m.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAddEditManagerDialog(BuildContext context, {Manager? manager}) {
    final nameController = TextEditingController(text: manager?.name ?? "");
    final pinController = TextEditingController(text: manager?.pin ?? "");
    final provider = Provider.of<ProjectProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: PremiumHeader(
          title: manager == null ? "ΝΕΟΣ ΥΠΕΥΘΥΝΟΣ" : "ΕΠΕΞΕΡΓΑΣΙΑ ΥΠΕΥΘΥΝΟΥ",
          icon: Icons.person_rounded,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Ονοματεπώνυμο", prefixIcon: Icon(Icons.badge_outlined))),
            const SizedBox(height: 16),
            TextField(controller: pinController, decoration: const InputDecoration(labelText: "PIN Σύνδεσης", prefixIcon: Icon(Icons.lock_outline)), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900))),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final m = Manager(
                  id: manager?.id ?? 0,
                  name: nameController.text.trim(),
                  pin: pinController.text.trim(),
                );
                if (manager == null) {
                  provider.addManager(m);
                } else {
                  provider.updateManager(m);
                }
                Navigator.pop(context);
              }
            },
            child: const Text("ΑΠΟΘΗΚΕΥΣΗ", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
