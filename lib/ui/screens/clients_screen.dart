import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';
import 'package:mtc2026/utils/excel_exporter.dart';
import 'package:mtc2026/utils/pdf_generator.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  String _searchQuery = "";
  String _filterStatus = "ΟΛΑ";

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final filteredClients = projectProvider.clients.where((c) {
      final matchesQuery = c.name.toLowerCase().contains(_searchQuery.toLowerCase()) || c.phone.contains(_searchQuery);
      final matchesStatus = _filterStatus == "ΟΛΑ" || c.status == _filterStatus;
      return matchesQuery && matchesStatus;
    }).toList();
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("ΠΕΛΑΤΟΛΟΓΙΟ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
            tooltip: "Εξαγωγή PDF",
            onPressed: () => PdfGenerator.generateAndShareClientList(clients: projectProvider.clients, settings: projectProvider.settings),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_rounded, color: Colors.green),
            tooltip: "Εξαγωγή Excel",
            onPressed: () => ExcelExporter.exportClients(projectProvider.clients),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showClientDialog(context),
        label: const Text("ΝΕΟΣ ΠΕΛΑΤΗΣ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        icon: const Icon(Icons.person_add_rounded),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
          child: Column(
            children: [
              _buildFilterBar(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Αναζήτηση πελάτη...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              Expanded(
                child: isDesktop
                    ? GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 3,
                        ),
                        itemCount: filteredClients.length,
                        itemBuilder: (context, index) => _ClientCard(
                          client: filteredClients[index],
                          onClick: () => _showClientDialog(context, client: filteredClients[index]),
                          onLongClick: () => _showClientDetails(context, filteredClients[index]),
                          onDelete: () => _showDeleteConfirm(context, filteredClients[index]),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredClients.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final client = filteredClients[index];
                          return _ClientCard(
                            client: client,
                            onClick: () => _showClientDialog(context, client: client),
                            onLongClick: () => _showClientDetails(context, client),
                            onDelete: () => _showDeleteConfirm(context, client),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final statuses = ["ΟΛΑ", "LEAD", "ACTIVE", "PAST"];
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final s = statuses[index];
          final isSelected = _filterStatus == s;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(s, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.blueGrey)),
              selected: isSelected,
              onSelected: (val) => setState(() => _filterStatus = s),
              selectedColor: Colors.blue,
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  void _showClientDialog(BuildContext context, {Client? client}) {
    showDialog(
      context: context,
      builder: (context) => _ClientEntryDialog(
        initialClient: client,
        onConfirm: (name, phone, email, status, followUpDate) {
          if (client == null) {
            Provider.of<ProjectProvider>(context, listen: false).addClient(Client(
              name: name, phone: phone, email: email, status: status, followUpDate: followUpDate,
            ));
          } else {
            Provider.of<ProjectProvider>(context, listen: false).updateClient(client.copyWith(
              name: name, phone: phone, email: email, status: status, followUpDate: followUpDate,
            ));
          }
        },
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text("ΔΙΑΓΡΑΦΗ ΠΕΛΑΤΗ", style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text("Είστε σίγουροι ότι θέλετε να διαγράψετε τον πελάτη '${client.name}';"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900))),
          ElevatedButton(
            onPressed: () {
              Provider.of<ProjectProvider>(context, listen: false).deleteClient(client.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("ΔΙΑΓΡΑΦΗ", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showClientDetails(BuildContext context, Client client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _ClientDetailsSheet(client: client),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final Client client;
  final VoidCallback onClick;
  final VoidCallback onLongClick;
  final VoidCallback onDelete;

  const _ClientCard({required this.client, required this.onClick, required this.onLongClick, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF4361EE);
    
    return PremiumCard(
      onTap: onClick,
      onLongPress: onLongClick,
      accentColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            alignment: Alignment.center,
            child: Text(
              client.name.isNotEmpty ? client.name[0].toUpperCase() : "?",
              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(client.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B), letterSpacing: 0.2), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    _StatusBadge(status: client.status),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(client.phone, style: TextStyle(color: color.withValues(alpha: 0.6), fontWeight: FontWeight.w900, fontSize: 10)),
                    if (client.followUpDate != null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.event_note_rounded, size: 10, color: Colors.orange.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Text(DateFormat('dd/MM').format(DateTime.fromMillisecondsSinceEpoch(client.followUpDate!)), style: const TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
            onPressed: onDelete,
            tooltip: "Διαγραφή Πελάτη",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.blue;
    if (status == "LEAD") color = Colors.orange;
    if (status == "PAST") color = Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 7, letterSpacing: 0.5)),
    );
  }
}

class _ClientEntryDialog extends StatefulWidget {
  final Client? initialClient;
  final Function(String, String, String, String, int?) onConfirm;

  const _ClientEntryDialog({this.initialClient, required this.onConfirm});

  @override
  State<_ClientEntryDialog> createState() => _ClientEntryDialogState();
}

class _ClientEntryDialogState extends State<_ClientEntryDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late String _status;
  int? _followUpDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialClient?.name ?? "");
    _phoneController = TextEditingController(text: widget.initialClient?.phone ?? "");
    _emailController = TextEditingController(text: widget.initialClient?.email ?? "");
    _status = widget.initialClient?.status ?? "ACTIVE";
    _followUpDate = widget.initialClient?.followUpDate;
  }

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF4361EE);
    
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
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: PremiumHeader(
                  title: widget.initialClient == null ? "ΝΕΟΣ ΠΕΛΑΤΗΣ" : "ΕΠΕΞΕΡΓΑΣΙΑ ΠΕΛΑΤΗ",
                  icon: Icons.person_add_rounded,
                  color: color,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Ονοματεπώνυμο", prefixIcon: Icon(Icons.person_outline))),
                    const SizedBox(height: 12),
                    TextField(controller: _phoneController, decoration: const InputDecoration(labelText: "Τηλέφωνο", prefixIcon: Icon(Icons.phone_outlined)), keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email_outlined)), keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(labelText: "Κατάσταση Πελάτη", prefixIcon: Icon(Icons.label_outline_rounded)),
                      items: ["LEAD", "ACTIVE", "PAST"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(context: context, initialDate: _followUpDate != null ? DateTime.fromMillisecondsSinceEpoch(_followUpDate!) : DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                        if (date != null) setState(() => _followUpDate = date.millisecondsSinceEpoch);
                      },
                      icon: const Icon(Icons.event_note_rounded, size: 18),
                      label: Text(_followUpDate == null ? "ΟΡΙΣΜΟΣ ΕΠΙΚΟΙΝΩΝΙΑΣ" : "ΕΠΙΚΟΙΝΩΝΙΑ: ${DateFormat('dd/MM/yy').format(DateTime.fromMillisecondsSinceEpoch(_followUpDate!))}"),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey.withValues(alpha: 0.6))))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_nameController.text.isNotEmpty) {
                            widget.onConfirm(_nameController.text, _phoneController.text, _emailController.text, _status, _followUpDate);
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: color),
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
}

class _ClientDetailsSheet extends StatelessWidget {
  final Client client;
  const _ClientDetailsSheet({required this.client});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(client.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
          const SizedBox(height: 16),
          _ActionRow(
            icon: Icons.phone,
            label: client.phone,
            onTap: () async {
              final uri = Uri.parse("tel:${client.phone}");
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
          if (client.email.isNotEmpty)
            _ActionRow(
              icon: Icons.email,
              label: client.email,
              onTap: () async {
                final uri = Uri.parse("mailto:${client.email}");
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
          const Divider(height: 32),
          const Text("ΙΣΤΟΡΙΚΟ ΕΡΓΩΝ", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blue, fontSize: 14)),
          const SizedBox(height: 8),
          FutureBuilder<List<Project>>(
            future: Provider.of<ProjectProvider>(context, listen: false).getProjectsForClient(client.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final projects = snapshot.data!;
              if (projects.isEmpty) return const Text("Δεν βρέθηκαν έργα.", style: TextStyle(color: Colors.grey));
              return Column(
                children: projects.map((p) => ListTile(
                  leading: const Icon(Icons.architecture, color: Colors.blue),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {}, // Navigate to project
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
